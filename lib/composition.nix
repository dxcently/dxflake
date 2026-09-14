# lib/composition.nix — the two-pass constructor.
#
# `mkDefault` sets definition PRIORITY; it cannot decide imports. `mkIf` cannot
# keep an imported module's declarations out of the graph that imported them.
# So selection is resolved FIRST, by an ordinary `lib.evalModules` over a tiny
# schema that knows nothing about NixOS, and the platform import list is
# assembled from the result. Nothing walks the filesystem: a dendrite exists
# because `modules/default.nix` names its path.
#
# A selection option may never read the NixOS/Home Manager configuration it is
# deciding — that is the circular import this split exists to prevent. Platform
# settings therefore ride `deferredModule` options and are evaluated only in
# the lane that was selected for them.
{ lib }:
let
  inherit (lib) mkOption types;

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

  # The schema every selection pass evaluates. `modules/default.nix` calls this
  # with its own catalogue, plus the group declarations that steer a user scope.
  # A group is written once and imported into both scopes; it tells them apart
  # by the `scope` argument ("system" or "home") each pass supplies.
  mkSchema =
    {
      catalogue,
      userModules ? [ ],
    }:
    { ... }:
    {
      options = {
        catalogue = mkOption {
          type = types.attrsOf types.path;
          readOnly = true;
          description = "Named path per capability. The constructor reads it back in pass two.";
        };

        dendrites = selectionScope catalogue;

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
                  };
                }
              ]
              ++ userModules;
            }
          );
        };

        nixos = mkOption {
          type = types.deferredModule;
          default = { };
          description = "This host's own NixOS settings and hardware, deferred until selection is complete.";
        };
      };

      config.catalogue = catalogue;
    };

  # ── Pass two ───────────────────────────────────────────────────────────────
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
in
rec {
  inherit
    mkSchema
    laneNames
    lanesFor
    implOf
    ;

  # Pass one. Ordinary lib.evalModules over the selection schema — no NixOS,
  # no package set, nothing that could depend on the result.
  evalSelection =
    { modules }:
    (lib.evalModules {
      inherit modules;
      specialArgs = {
        inherit lib;
        scope = "system";
      };
    }).config;

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
    in
    {
      host = hostName;
      aggregation = lib.attrNames (lib.filterAttrs (_: a: a.enable) (selection.aggregation or { }));
      dendrites = describe selection.dendrites;
      users = lib.mapAttrs (_: u: {
        definition = toString u.definition;
        homeManager = u.homeManager.enable;
        aggregation = lib.attrNames (lib.filterAttrs (_: a: a.enable) (u.aggregation or { }));
        dendrites = describe u.dendrites;
      }) selection.users;
    };

  # Pass two. Assemble the platform module list from the resolved selection.
  mkNixosHost =
    {
      nixpkgs,
      hostName,
      selectionModules,
      nucleus,
      homeManagerModule,
      specialArgs ? { },
      extraModules ? [ ],
      system ? "x86_64-linux",
    }:
    let
      selection = evalSelection { modules = selectionModules; };
      inherit (selection) catalogue;

      systemLanes = lanesFor {
        inherit catalogue;
        selected = selection.dendrites;
        lane = "nixos";
        scope = "for the system";
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
      ++ [ selection.nixos ];
    in
    if strandedHome != [ ] then
      throw "host '${hostName}': ${lib.concatStringsSep "; " strandedHome}"
    else
      {
        inherit selection;
        inventory = inventoryOf { inherit hostName selection; };
        system = nixpkgs.lib.nixosSystem {
          inherit modules;
          specialArgs = args;
        };
      };
}
