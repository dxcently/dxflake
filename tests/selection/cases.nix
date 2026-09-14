# Executable schema cases. Each attribute is one case, evaluated on its own by
# tests/selection/run.sh; negative cases are expected to throw with a message
# the runner greps for, so "clear error" is evidence rather than a claim.
{ lib }:
let
  composition = import ../../lib/composition.nix { inherit lib; };
  registry = import ./registry.nix;

  select =
    mod:
    composition.evalSelection {
      inherit registry;
      modules = [ mod ];
    };

  # Force the whole resolution: selection, inventory, and every lane module the
  # host would import. Without this a throw hiding in an unforced thunk passes.
  resolve =
    mod:
    let
      selection = select mod;
      inv = composition.inventoryOf {
        hostName = "fixture";
        inherit selection;
      };
      lanes = {
        system = composition.lanesFor {
          inherit (selection) catalogue;
          selected = selection.dendrites;
          lane = "nixos";
          scope = "for the system";
        };
        home = lib.mapAttrs (
          userName: u:
          composition.lanesFor {
            inherit (selection) catalogue;
            selected = u.dendrites;
            lane = "homeManager";
            scope = "by user '${userName}'";
          }
        ) selection.users;
      };
    in
    builtins.deepSeq (builtins.toJSON inv) (builtins.deepSeq lanes { inherit selection inv lanes; });
in
rec {
  # ── A disabled implementation is never imported ────────────────────────────
  # landmine/default.nix throws on import; selecting everything around it and
  # forcing the resolution must still succeed.
  disabledIsInert = (resolve { dendrites.systemonly.enable = true; }).inv.host;

  # An enabled dendrite imports only the provider that was chosen. The
  # landmine provider sits beside dunst in the same registry.
  unselectedProviderIsInert =
    (resolve {
      dendrites.notifications = {
        enable = true;
        provider = "dunst";
      };
    }).inv.dendrites.notifications.provider;

  # aggregations/landmine/default.nix throws on import. It is discovered — it is
  # a directory with a default.nix right beside the ones that are selected — so
  # resolving a host that does not select it proves discovery never reads a body.
  unselectedAggregationIsInert =
    (resolve {
      aggregation.workstation.enable = true;
      users.alice = {
        definition = ./users/alice.nix;
        homeManager.enable = true;
        aggregation.desk.enable = true;
      };
    }).inv.host;

  # ── Provider diagnostics ───────────────────────────────────────────────────
  missingProvider = (resolve { dendrites.notifications.enable = true; }).inv.host;

  unknownProvider =
    (resolve {
      dendrites.notifications = {
        enable = true;
        provider = "nope";
      };
    }).inv.host;

  providerOnSingleImpl =
    (resolve {
      dendrites.systemonly = {
        enable = true;
        provider = "mako";
      };
    }).inv.host;

  # ── Lane diagnostics ───────────────────────────────────────────────────────
  # mako is home-only; selecting it at system scope must fail, not be skipped.
  systemScopeWantsHomeOnlyProvider =
    (resolve {
      dendrites.notifications = {
        enable = true;
        provider = "mako";
      };
    }).lanes.system;

  systemScopeWantsHomeOnlyDendrite = (resolve { dendrites.homeonly.enable = true; }).lanes.system;

  homeScopeWantsSystemOnlyDendrite =
    (resolve {
      users.alice = {
        definition = ./users/alice.nix;
        homeManager.enable = true;
        dendrites.systemonly.enable = true;
      };
    }).lanes.home;

  # ── Unknown names ──────────────────────────────────────────────────────────
  unknownDendrite = (resolve { dendrites.frobnicate.enable = true; }).inv.host;

  unknownAggregation = (resolve { aggregation.frobnicate.enable = true; }).inv.host;

  # A provider selector an aggregation does not own is a missing option, not a
  # silently ignored line. This is the case the gate step's freeform attrset
  # defers rather than swallows.
  unknownAggregationSelector =
    (resolve {
      aggregation.workstation = {
        enable = true;
        compositor.provider = "hyprland";
      };
    }).inv.host;

  # ── The host interface: provider choices under the aggregation ─────────────
  # The host names its implementation on the aggregation that owns the
  # dendrite, and needs no top-level dendrites override to do it.
  aggregationProviderSelector =
    (resolve {
      aggregation.workstation = {
        enable = true;
        notifications.provider = "herald";
      };
    }).inv.dendrites.notifications.provider;

  # A top-level selection still outranks the aggregation's mkDefault.
  hostOverridesAggregationProvider =
    (resolve {
      aggregation.workstation.enable = true;
      dendrites.notifications.provider = "herald";
    }).inv.dendrites.notifications.provider;

  # Two aggregations naming the same dendrite on the same terms merge into ONE
  # selection — they do not instantiate it twice.
  aggregationsMergeOnSharedDendrite =
    let
      r = resolve {
        aggregation.workstation.enable = true;
        aggregation.annex.enable = true;
      };
    in
    r.inv.dendrites.notifications.provider == "dunst" && builtins.length r.lanes.system == 2;

  # Two aggregations choosing different providers for it collide; import order
  # never picks a winner.
  conflictingAggregationProviders =
    (resolve {
      aggregation.workstation.enable = true;
      aggregation.kiosk.enable = true;
    }).inv.dendrites.notifications.provider;

  # false beats a default true.
  hostDisablesAggregationMember =
    (resolve {
      aggregation.workstation.enable = true;
      dendrites.systemonly.enable = false;
    }).inv.dendrites ? systemonly;

  # A preference that rides along reaches the platform pass as a module, not as
  # something the selection pass evaluated.
  aggregationRidesPlatformSettings =
    let
      r = resolve { aggregation.workstation.enable = true; };
    in
    (lib.evalModules {
      modules = [
        {
          options.networking.hostName = lib.mkOption {
            type = lib.types.str;
            default = "";
          };
        }
        r.selection.nixos
      ];
    }).config.networking.hostName;

  # ── Scopes ─────────────────────────────────────────────────────────────────
  # The same aggregation one scope down: a user turning it on gets its home
  # membership, and the system scope stays empty — the two halves of one
  # aggregation reach different evaluators.
  userAggregationContributesHomeMembers =
    let
      r = resolve {
        users.alice = {
          definition = ./users/alice.nix;
          homeManager.enable = true;
          aggregation.desk.enable = true;
        };
      };
    in
    r.inv.users.alice.dendrites.notifications.provider == "dunst" && r.lanes.system == [ ];

  # A user outranks the aggregation that attached them, independently of the
  # system selection.
  userOverridesAggregationProvider =
    (resolve {
      users.alice = {
        definition = ./users/alice.nix;
        homeManager.enable = true;
        aggregation.desk = {
          enable = true;
          notifications.provider = "mako";
        };
      };
    }).inv.users.alice.dendrites.notifications.provider;

  # ── Users ──────────────────────────────────────────────────────────────────
  # Two users, same capability, different providers, each in its own scope.
  twoUserScopes =
    let
      r = resolve {
        users.alice = {
          definition = ./users/alice.nix;
          homeManager.enable = true;
          dendrites.notifications = {
            enable = true;
            provider = "mako";
          };
        };
        users.bob = {
          definition = ./users/bob.nix;
          homeManager.enable = true;
          dendrites.notifications = {
            enable = true;
            provider = "dunst";
          };
        };
      };
    in
    "${r.inv.users.alice.dendrites.notifications.provider}+${r.inv.users.bob.dendrites.notifications.provider}";

  # Selecting a capability for the system does not select it for any user.
  scopesDoNotLeak =
    let
      r = resolve {
        dendrites.notifications = {
          enable = true;
          provider = "dunst";
        };
        users.alice = {
          definition = ./users/alice.nix;
          homeManager.enable = true;
        };
      };
    in
    r.lanes.home.alice == [ ];

  # ── Home Manager absence ───────────────────────────────────────────────────
  # A home selection with the lane switched off is a configuration error.
  homeSelectionWithoutHomeManager = mkHost {
    users.alice = {
      definition = ./users/alice.nix;
      homeManager.enable = false;
      dendrites.notifications = {
        enable = true;
        provider = "mako";
      };
    };
  };

  # A host whose users all have it off resolves cleanly and attaches no home
  # lanes at all.
  homeManagerAbsent =
    let
      r = resolve {
        dendrites.systemonly.enable = true;
        users.bob = {
          definition = ./users/bob.nix;
          homeManager.enable = false;
        };
      };
    in
    !r.inv.users.bob.homeManager && r.lanes.home.bob == [ ];

  # ── Host assembly ──────────────────────────────────────────────────────────
  # Only the strandedHome guard is forced here; nixosSystem is not evaluated,
  # so these cases stay cheap.
  mkHost =
    mod:
    (composition.mkNixosHost {
      nixpkgs = {
        lib.nixosSystem = _: throw "nixosSystem must not be evaluated by a selection case";
      };
      hostName = "fixture";
      inherit registry;
      hostModules = [ mod ];
      nucleus = { };
      homeManagerModule = { };
    }).inventory.host;
}
