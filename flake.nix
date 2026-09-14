{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    aagl = {
      url = "github:ezkea/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Melete and Mneme come from their canonical GitHub repositories, pinned to
    # the default branch (master). A checkout tip on whichever box happens to be
    # rebuilding is not upstream, so the flake no longer treats it as one.
    #
    # Both repos are PRIVATE, so fetching them needs GitHub credentials at
    # EVALUATION time. `git+https:` goes through git, which picks up the `gh`
    # credential helper this user already has configured — so evaluate as that
    # user (`nh os switch` does) rather than as root.
    #
    # `git+https:` locks to a commit and copies only tracked files (no .git, no
    # target/, .gitignore honored). A source change is therefore picked up
    # explicitly, not silently:
    #   nix flake update melete-src   # or mneme-src
    # To build a DIRTY worktree without committing, override for that one
    # rebuild — `path:` re-hashes the directory as it is on disk:
    #   nixos-rebuild switch --flake .#sakaki \
    #     --override-input melete-src path:/home/khoa/melete
    #
    # Only sakaki forces these (dx.melete/dx.mneme are false elsewhere, and
    # module args are lazy), so no other host ever builds them.
    melete-src = {
      url = "git+https://github.com/noah427/melete";
      flake = false;
    };
    mneme-src = {
      url = "git+https://github.com/noah427/mneme";
      flake = false;
    };
    # uv2nix stack: builds the kimi-cli agent (pkgs/kimi-cli) from its uv.lock.
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ── Aoide (AoideOS) integration ────────────────────────────────────────
    # dxflake consumes Aoide as a flake input and, on integrating hosts, runs
    # Aoide's module structure (nucleus/facets/song walked from the input) —
    # the structure a host RUNS is Aoide's; dxflake's own tree stays the venue
    # (hosts, hardware, secrets). Pin the published Aoide commit so every host
    # fetches the same source without a local Aoide checkout.
    aoide = {
      url = "git+https://github.com/dxcently/Aoide.git?ref=main&rev=3b168ce40f4ce7f6fde73d2dcb418d3d3870247f";
    };
    quickshell = {
      # Follows Aoide's own quickshell pin — the facet QML and the runtime
      # must never drift apart.
      follows = "aoide/quickshell";
    };
  };
  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      home-manager,
      ...
    }@inputs:
    let
      inherit (nixpkgs) lib;
      system = "x86_64-linux";
      username = "khoa";

      composition = import ./lib/composition.nix { inherit lib; };

      # ── The Aoide seam ───────────────────────────────────────────────────
      # Everything below reaches INTO the Aoide input's tree, because the Aoide
      # flake exports packages, songbookManifest and aoideOptions but no
      # nixosModules and no lib. Four minimal public exports would close every
      # one of these paths: nixosModules.default, a songbook module,
      # lib.livery.resolve, and overlays.default. Until they exist this is the
      # honest shape of the dependency, named in one place rather than spread
      # across hosts.
      aoideTree = [
        (inputs.aoide + "/modules/default.nix")
        # The songs, named rather than walked. The walker pulled exactly these
        # five rice.nix files (`_widgets/` is shelved by its prefix); each song
        # self-gates on `aoide.song`, so naming them changes nothing but makes
        # the set visible. It collapses to one import when Aoide exports a
        # songbook module.
        (inputs.aoide + "/song/songbook/etude/rice.nix")
        (inputs.aoide + "/song/songbook/fugue/rice.nix")
        (inputs.aoide + "/song/songbook/nocturne/rice.nix")
        (inputs.aoide + "/song/songbook/quodlibet/rice.nix")
        (inputs.aoide + "/song/songbook/sonata/rice.nix")
        {
          nixpkgs.overlays = [
            (import (inputs.aoide + "/lib/pkgs.nix") { inherit lib; }).overlay
            (_final: _prev: { aoide = inputs.aoide.packages.${system}.default; })
          ];
        }
      ];

      hosts = lib.genAttrs [ "chiyo" "osaka" "sakaki" "yomi-strix" ] (
        name:
        composition.mkNixosHost {
          inherit nixpkgs system;
          hostName = name;
          selectionModules = [
            ./modules
            ./hosts/${name}
          ];
          nucleus = ./modules/nucleus;
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          extraModules = aoideTree ++ [ inputs.disko.nixosModules.disko ];
          specialArgs = {
            inherit username nixpkgs-stable;
            resolveAoideLivery = (import (inputs.aoide + "/lib/livery.nix") { inherit lib; }).resolve;
            inputs = inputs // {
              aoide = inputs.aoide.inputs.aoide;
            };
          };
        }
      );
    in
    {
      nixosConfigurations = lib.mapAttrs (_: h: h.system) hosts;

      # What each host actually resolved: dendrites, providers, users, lanes
      # and the file each came from. Derived from selection, never maintained
      # by hand — `nix eval --json .#inventory.osaka` is the review surface.
      inventory = lib.mapAttrs (_: h: h.inventory) hosts;
    };
}
