# lib/composition.nix — the constructor.
#
# `mkDefault` sets definition PRIORITY; it cannot decide imports. `mkIf` cannot
# keep an imported module's declarations out of the graph that imported them.
# So selection is resolved FIRST, by ordinary `lib.evalModules` over a tiny
# schema that knows nothing about NixOS, and the platform import list is
# assembled from the result.
#
# Selection itself runs in two steps, because the host interface nests provider
# choices under the aggregation that owns them
# (`aggregation.shell.compositor.provider`) and those option names come from
# the aggregation's own body:
#
#   gate   — every discovered aggregation declares only `enable`; the rest of
#            its attrset is freeform and ignored. This step answers one
#            question: which aggregations does this host, or one of its users,
#            select?
#   select — the selected bodies are imported, declare their real nested
#            options, and write their membership. Nothing else is read.
#
# The evaluation boundary, stated exactly: `modules/aggregations/default.nix`
# names directories without importing them; an aggregation body is imported iff
# the host or one of its users selected it; a dendrite implementation and a
# provider file are imported only in the platform pass, iff selection kept them.
#
# A selection option may never read the NixOS/Home Manager configuration it is
# deciding — that is the circular import this split exists to prevent. Platform
# settings therefore ride `deferredModule` options and are evaluated only in
# the lane that was selected for them.
{ lib }:
let
  inherit (lib)
    mkOption
    mkIf
    mkMerge
    mkDefault
    types
    ;

  # A lane is a module for one evaluator. A dendrite exposes the lanes it
  # actually supports and no empty stand-ins for the rest.
  laneNames = [
    "nixos"
    "darwin"
    "homeManager"
  ];

  # One selection scope: for each catalogued capability, whether it is selected
  # here and which implementation answers. Generated per catalogue name, so an
  # unknown dendrite fails as an option that does not exist, naming the file
  # that asked for it.
  selectionScope =
    catalogue:
    lib.mapAttrs (
      name: _:
      mkOption {
        type = types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Select ${name} in this scope.";
            };
            provider = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Which implementation of ${name} answers in this scope.";
            };
          };
        };
        default = { };
        description = "Selection of the ${name} dendrite.";
      }
    ) catalogue;

  # The half of an aggregation body that answers in one scope: the scope names
  # are the body's own attribute names, `system` and `home`.
  halfOf = body: scope: body.${scope} or { };

  # ── The aggregation interface ──────────────────────────────────────────────
  # `enable` for every discovered aggregation, plus — once the body is in hand —
  # one `<dendrite>.provider` for each provider-bearing member that aggregation
  # groups in this scope. Those nested selectors are the host-facing interface;
  # a single-implementation member gets no provider option at all.
  aggregationScope =
    {
      aggregations,
      bodies,
      scope,
    }:
    lib.mapAttrs (
      name: _:
      let
        body = bodies.${name} or null;
        half = if body == null then { } else halfOf body scope;
      in
      mkOption {
        type = types.submodule (
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = false;
                description =
                  if body == null then
                    "Select the ${name} aggregation in this scope."
                  else
                    body.description or "Select the ${name} aggregation in this scope.";
              };
            }
            // lib.mapAttrs (member: default: {
              provider = mkOption {
                type = types.nullOr types.str;
                inherit default;
                description = "Which implementation of ${member} the ${name} aggregation selects here.";
              };
            }) (half.providers or { });
          }
          # Gate step: the nested selectors are not declared yet, because the
          # body that names them has not been read. Accept and ignore them; the
          # select step is where they are typed.
          // lib.optionalAttrs (bodies == null) {
            freeformType = types.attrsOf types.anything;
          }
        );
        default = { };
        description = "Selection of the ${name} aggregation.";
      }
    ) aggregations;

  # What one selected aggregation contributes to one scope. Membership is
  # `mkDefault`, so an ordinary selection outranks it, two aggregations naming
  # the same member merge, and two that choose different providers for it
  # collide on `dendrites.<name>.provider` rather than letting import order
  # pick a winner. The body carries no gate of its own: it is data, and this is
  # the only place it is wrapped.
  aggregationConfig =
    {
      bodies,
      scope,
      root,
    }:
    lib.mapAttrsToList (
      name: body:
      let
        half = halfOf body scope;
        cfg = root.aggregation.${name};
      in
      mkIf cfg.enable (
        {
          dendrites =
            lib.genAttrs (half.members or [ ]) (_: {
              enable = mkDefault true;
            })
            // lib.mapAttrs (member: _: {
              enable = mkDefault true;
              provider = mkDefault cfg.${member}.provider;
            }) (half.providers or { });
        }
        // lib.optionalAttrs (half ? nixos) { inherit (half) nixos; }
        // lib.optionalAttrs (half ? homeManager) { homeManager.config = half.homeManager; }
      )
    ) bodies;

  # The schema one selection step evaluates. `bodies = null` is the gate step.
  mkSchema =
    {
      catalogue,
      aggregations,
      bodies ? null,
    }:
    { config, ... }:
    let
      known = if bodies == null then { } else bodies;
    in
    {
      options = {
        catalogue = mkOption {
          type = types.attrsOf types.path;
          readOnly = true;
          description = "Named path per capability. The constructor reads it back in the platform pass.";
        };

        dendrites = selectionScope catalogue;

        aggregation = aggregationScope {
          inherit aggregations bodies;
          scope = "system";
        };

        users = mkOption {
          default = { };
          description = "Users attached to this host, and what each selects for its own home lane.";
          type = types.attrsOf (
            types.submoduleWith {
              shorthandOnlyDefinesConfig = true;
              specialArgs = {
                inherit lib;
                scope = "home";
              };
              modules = [
                (
                  { config, ... }:
                  {
                    options = {
                      definition = mkOption {
                        type = types.path;
                        description = "Shared user definition: account lanes plus optional home preferences.";
                      };
                      homeManager.enable = mkOption {
                        type = types.bool;
                        default = false;
                        description = "Evaluate this user's home lane. Off means no Home Manager module is imported for them at all.";
                      };
                      homeManager.config = mkOption {
                        type = types.deferredModule;
                        default = { };
                        description = "Extra home settings for this user, evaluated only in the home lane.";
                      };
                      dendrites = selectionScope catalogue;
                      aggregation = aggregationScope {
                        inherit aggregations bodies;
                        scope = "home";
                      };
                    };

                    config = mkMerge (aggregationConfig {
                      bodies = known;
                      scope = "home";
                      root = config;
                    });
                  }
                )
              ];
            }
          );
        };

        nixos = mkOption {
          type = types.deferredModule;
          default = { };
          description = "This host's own NixOS settings and hardware, deferred until selection is complete.";
        };
      };

      config = mkMerge (
        [ { inherit catalogue; } ]
        ++ aggregationConfig {
          bodies = known;
          scope = "system";
          root = config;
        }
      );
    };

  # ── The platform pass ──────────────────────────────────────────────────────
  # Only what selection resolved is imported. A catalogue entry that was never
  # enabled is never `import`ed, and an unselected provider file is never read.

  # Resolve one enabled capability to its implementation attrset.
  implOf =
    catalogue: name: provider:
    let
      entry = import catalogue.${name};
      providers = entry.providers or null;
      names = lib.concatStringsSep ", " (lib.attrNames (entry.providers or { }));
    in
    if providers != null then
      if provider == null then
        throw "dendrite '${name}' is enabled but chose no provider; available providers: ${names}"
      else if !(providers ? ${provider}) then
        throw "dendrite '${name}' has no provider '${provider}'; available providers: ${names}"
      else
        {
          impl = import providers.${provider};
          label = "${name}/${provider}";
        }
    else if provider != null then
      throw "dendrite '${name}' has a single implementation and takes no provider (got '${provider}')"
    else
      {
        impl = entry;
        label = name;
      };

  # Resolve one enabled capability to the lane this scope needs. Selecting a
  # lane a dendrite does not support is an error, not a silently skipped import.
  laneOf =
    {
      catalogue,
      name,
      provider,
      lane,
      scope,
    }:
    let
      d = implOf catalogue name provider;
      supported = lib.filter (l: d.impl ? ${l}) laneNames;
    in
    if d.impl ? ${lane} then
      d.impl.${lane}
    else
      throw "dendrite '${d.label}' is selected ${scope} but exposes no ${lane} lane; it supports: ${
        if supported == [ ] then "no lanes at all" else lib.concatStringsSep ", " supported
      }";

  # Every lane module for one selection scope, in catalogue order.
  lanesFor =
    {
      catalogue,
      selected,
      lane,
      scope,
    }:
    lib.concatMap (
      name:
      lib.optional selected.${name}.enable (laneOf {
        inherit
          catalogue
          name
          lane
          scope
          ;
        inherit (selected.${name}) provider;
      })
    ) (lib.attrNames catalogue);

  enabledNames = selected: lib.attrNames (lib.filterAttrs (_: d: d.enable) selected);

  # ── Override records ───────────────────────────────────────────────────────
  # Some fixes belong to a CAPABILITY rather than to a host: a package whose
  # upstream build broke, a setting every machine that runs the thing wants. A
  # record names the dendrites it is about and, optionally, the hosts it is
  # confined to; the constructor applies it to the hosts that actually selected
  # one of those dendrites. It does not select anything — a record targeting a
  # capability nobody chose simply never applies.
  #
  # The evaluation boundary here is WEAKER than selection's, and this is the
  # honest statement of it: every host imports every record file, because
  # matching is reading. What stays unevaluated is the work — `overlay` and the
  # lane modules are functions, and an unmatched record's functions are never
  # called. Keep imports and package computation inside them; metadata that
  # computes defeats this, and the tests prove only the function bodies.
  #
  # `darwin` is absent on purpose: there is no darwin constructor to apply it,
  # and a field that is silently dropped is worse than one that does not exist.
  overrideFields = [
    "dendrites"
    "hosts"
    "overlay"
    "nixos"
    "homeManager"
  ];

  # Read and validate one record. Typos fail here, naming the record and the
  # file, rather than applying to nothing and looking like a working fix.
  readRecord =
    {
      catalogue,
      knownHosts,
      name,
      path,
    }:
    let
      body = import path;
      where = "override record '${name}' (${toString path})";
      unknown = lib.subtractLists overrideFields (lib.attrNames body);
      targets = body.dendrites or [ ];
      strays = lib.filter (d: !(catalogue ? ${d})) targets;
      hosts = body.hosts or null;
      badHosts = lib.filter (h: !(lib.elem h knownHosts)) (if hosts == null then [ ] else hosts);
      carries = lib.filter (f: body ? ${f}) [
        "overlay"
        "nixos"
        "homeManager"
      ];
    in
    if unknown != [ ] then
      throw "${where} has unknown field(s): ${lib.concatStringsSep ", " unknown}; a record takes only ${lib.concatStringsSep ", " overrideFields}"
    else if !(lib.isList targets) || targets == [ ] then
      throw "${where} names no dendrites; a record must say which capabilities it is about"
    else if strays != [ ] then
      throw "${where} targets unknown dendrite(s): ${lib.concatStringsSep ", " strays}; every target must be a catalogue name"
    else if badHosts != [ ] then
      throw "${where} is confined to unknown host(s): ${lib.concatStringsSep ", " badHosts}"
    else if carries == [ ] then
      throw "${where} carries nothing to apply; give it an overlay, a nixos module or a homeManager module"
    else
      {
        inherit name hosts;
        dendrites = targets;
      }
      // lib.getAttrs carries body;

  # Which records apply to this host, and to which of its users.
  #
  # A record matches the HOST when its host filter admits this host and any
  # dendrite it targets was selected here — for the system OR by one of its
  # users, because `useGlobalPkgs` means a home lane draws from the host's own
  # package set and there is no separate home one to fix. Its `overlay` and
  # `nixos` module then apply once, however many of its targets were selected.
  #
  # A record matches a USER when its host filter admits this host and that
  # user's own home selection hits a target; only then does its `homeManager`
  # module ride that user's lane. The alternative — every user on a matched
  # host — would put one person's fix in everyone else's home.
  #
  # Order is record name, so what the list holds does not depend on the
  # filesystem. Overlays then compose the ordinary Nix way, each seeing the
  # previous one as `prev`: later wins on the same attribute, and there is no
  # overlap detection beyond that.
  overridesFor =
    {
      catalogue,
      overrides,
      knownHosts,
      hostName,
      selection,
    }:
    let
      records = lib.mapAttrsToList (
        name: path:
        readRecord {
          inherit
            catalogue
            knownHosts
            name
            path
            ;
        }
      ) overrides;

      homeOf = u: enabledNames u.dendrites;
      here = lib.unique (
        enabledNames selection.dendrites ++ lib.concatMap homeOf (lib.attrValues selection.users)
      );

      admitsHost = r: r.hosts == null || lib.elem hostName r.hosts;
      hits = names: r: lib.any (d: lib.elem d names) r.dendrites;

      forHost = lib.filter (r: admitsHost r && hits here r) records;
      carried = field: rs: lib.concatMap (r: lib.optional (r ? ${field}) r.${field}) rs;
    in
    {
      overlays = carried "overlay" forHost;
      nixos = carried "nixos" forHost;
      homeManager = lib.mapAttrs (
        _: u: carried "homeManager" (lib.filter (r: admitsHost r && hits (homeOf u) r) records)
      ) selection.users;
      matched = map (r: r.name) forHost;
    };
in
rec {
  inherit
    mkSchema
    laneNames
    lanesFor
    implOf
    overridesFor
    ;

  # Gate, then select. Ordinary lib.evalModules both times — no NixOS, no
  # package set, nothing that could depend on the result.
  #
  # An aggregation body is DATA (`members`, `providers`, `nixos`), so it has no
  # way to enable another aggregation: the gate step's answer is the select
  # step's answer, and no recursion machinery is needed to say so.
  evalSelection =
    { registry, modules }:
    let
      inherit (registry) catalogue aggregations;

      eval =
        bodies:
        (lib.evalModules {
          modules = [
            (mkSchema { inherit catalogue aggregations bodies; })
          ]
          ++ modules;
          specialArgs = {
            inherit lib;
            scope = "system";
          };
        }).config;

      gate = eval null;

      chosen = agg: lib.attrNames (lib.filterAttrs (_: a: a.enable) agg);

      selected = lib.unique (
        chosen gate.aggregation ++ lib.concatMap (u: chosen u.aggregation) (lib.attrValues gate.users)
      );
    in
    eval (lib.genAttrs selected (name: import aggregations.${name}));

  # A host's resolved shape: what it selected, from where, for which lane.
  # Generated from the selection, never maintained by hand.
  inventoryOf =
    { hostName, selection }:
    let
      inherit (selection) catalogue;
      describe =
        selected:
        lib.mapAttrs (name: d: {
          inherit (d) provider;
          source = toString catalogue.${name};
        }) (lib.filterAttrs (_: d: d.enable) selected);
      chosen = agg: lib.attrNames (lib.filterAttrs (_: a: a.enable) agg);
    in
    {
      host = hostName;
      aggregation = chosen selection.aggregation;
      dendrites = describe selection.dendrites;
      users = lib.mapAttrs (_: u: {
        definition = toString u.definition;
        homeManager = u.homeManager.enable;
        aggregation = chosen u.aggregation;
        dendrites = describe u.dendrites;
      }) selection.users;
    };

  # The platform pass. Assemble the module list from the resolved selection.
  mkNixosHost =
    {
      nixpkgs,
      hostName,
      knownHosts ? [ hostName ],
      registry,
      hostModules,
      nucleus,
      homeManagerModule,
      specialArgs ? { },
      extraModules ? [ ],
      system ? "x86_64-linux",
    }:
    let
      selection = evalSelection {
        inherit registry;
        modules = hostModules;
      };
      inherit (selection) catalogue;

      systemLanes = lanesFor {
        inherit catalogue;
        selected = selection.dendrites;
        lane = "nixos";
        scope = "for the system";
      };

      # Capability-scoped fixes, resolved once selection is final and applied
      # before anything evaluates a package set.
      overrides = overridesFor {
        inherit
          catalogue
          knownHosts
          hostName
          selection
          ;
        overrides = registry.overrides or { };
      };

      # Home Manager is wired only where a user actually asked for it; a host
      # with no home user never imports it. Asking for a home dendrite with the
      # lane switched off is a configuration error, not a quiet no-op.
      args = specialArgs // {
        inherit system;
        host = hostName;
      };

      hmUsers = lib.filterAttrs (_: u: u.homeManager.enable) selection.users;
      strandedHome = lib.concatMap (
        userName:
        let
          u = selection.users.${userName};
          wanted = enabledNames u.dendrites;
        in
        lib.optional (!u.homeManager.enable && wanted != [ ])
          "user '${userName}' has homeManager.enable = false but selects home dendrites: ${lib.concatStringsSep ", " wanted}"
      ) (lib.attrNames selection.users);

      userDefinition = u: import u.definition;

      accountLanes = lib.mapAttrsToList (
        userName: u:
        let
          d = userDefinition u;
        in
        if d ? nixos then
          d.nixos
        else
          throw "user '${userName}' definition ${toString u.definition} exposes no nixos lane; it cannot create an account on this host"
      ) selection.users;

      homeFor =
        userName: u:
        let
          d = userDefinition u;
        in
        {
          imports =
            lib.optional (d ? homeManager) d.homeManager
            ++ lanesFor {
              inherit catalogue;
              selected = u.dendrites;
              lane = "homeManager";
              scope = "by user '${userName}'";
            }
            ++ (overrides.homeManager.${userName} or [ ])
            ++ [ u.homeManager.config ];
        };

      homeWiring = {
        imports = [ homeManagerModule ];
        home-manager = {
          useUserPackages = true;
          useGlobalPkgs = true;
          backupFileExtension = "backup";
          extraSpecialArgs = args;
          users = lib.mapAttrs homeFor hmUsers;
        };
      };

      modules = [
        nucleus
      ]
      ++ accountLanes
      ++ systemLanes
      ++ lib.optional (hmUsers != { }) homeWiring
      ++ extraModules
      # A record outranks everything the constructor imported on its behalf; the
      # host's own module still outranks the record.
      ++ overrides.nixos
      ++ lib.optional (overrides.overlays != [ ]) { nixpkgs.overlays = overrides.overlays; }
      ++ [ selection.nixos ];
    in
    if strandedHome != [ ] then
      throw "host '${hostName}': ${lib.concatStringsSep "; " strandedHome}"
    else
      {
        inherit selection;
        inventory = inventoryOf { inherit hostName selection; } // {
          overrides = overrides.matched;
        };
        system = nixpkgs.lib.nixosSystem {
          inherit modules;
          specialArgs = args;
        };
      };
}
