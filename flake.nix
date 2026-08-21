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
    hermes-agent = {
      url = "github:NousResearch/hermes-agent";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
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
    # (hosts, hardware, secrets). git+file pins to Aoide's COMMITTED state
    # (main HEAD), so Aoide's in-flight working-tree edits never leak into
    # dxflake builds. The rev was hand-pinned because Aoide's worktree carried
    # an uncommitted diff at pin time; with ?rev= explicit, `nix flake update
    # aoide` is now a no-op. Advance by bumping ?rev= to Aoide's new committed
    # HEAD; drop ?rev= (back to plain `nix flake update aoide`) only once
    # Aoide's worktree is clean.
    aoide = {
      url = "git+file:///home/khoa/Aoide?rev=5dedff02b0123e2d74bb54609eb93d983d69ca7f";
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
      system = "x86_64-linux";
      username = "khoa";

      # Shared by dxflake's own walk and the Aoide walk: every .nix under a
      # dir, shelved by a `_` prefix (dxflake/Aoide discipline, identical).
      walk =
        dir:
        builtins.filter (
          p:
          let
            s = toString p;
          in
          nixpkgs.lib.hasSuffix ".nix" s && !(nixpkgs.lib.hasInfix "/_" s)
        ) (nixpkgs.lib.filesystem.listFilesRecursive dir);

      # withAoide = true adds Aoide's walked module tree + songbook and the
      # package overlays its modules expect. Everything Aoide ships is inert
      # until the host flips aoide.* flags (aoide.enable / facets / dendrites
      # all default OFF; aoide.song defaults to sonata, which only sets
      # aoide.livery — read by facets alone). Activation is the host's own
      # flag edit, never this file.
      mkHost =
        name: withAoide:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            host = name;
            inherit
              username
              inputs
              system
              nixpkgs-stable
              ;
          };
          modules =
            let
              discovered = walk ./modules;
              aoideModules = walk (inputs.aoide + "/modules");
              aoideSongbook = walk (inputs.aoide + "/song/songbook");
              # The Aoide seam: pkgs.aoide (the CLI core) + the packages
              # walker overlay (hyprglass, …) — Aoide's own mkHost adds
              # exactly these two.
              aoideSeam = {
                nixpkgs.overlays = [
                  (import (inputs.aoide + "/lib/pkgs.nix") { inherit (nixpkgs) lib; }).overlay
                  (_final: _prev: { aoide = inputs.aoide.packages.${system}.default; })
                ];
              };
            in
            discovered
            ++ [
              inputs.disko.nixosModules.disko
              ./hosts/${name}
            ]
            ++ nixpkgs.lib.optionals withAoide (aoideModules ++ aoideSongbook ++ [ aoideSeam ]);
        };
    in
    {
      nixosConfigurations = {
        chiyo = mkHost "chiyo" false;
        # Aoide's structure is walked in, asleep — flip aoide.* flags (and
        # shelve the replaced dxflake dendrites) when Aoide is ready.
        osaka = mkHost "osaka" true;
        sakaki = mkHost "sakaki" false;
        yomi-strix = mkHost "yomi-strix" true;
      };
    };
}
