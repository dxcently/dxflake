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
    # Melete and Mneme are developed in ~/<name> on sakaki, and those
    # checkouts are what the flake builds now — no more fetching a release
    # asset off the private GitHub repo (see pkgs/melete-package.nix).
    #
    # `git+file:` locks to a commit and copies only tracked files (no .git, no
    # target/, .gitignore honored). A source change is therefore picked up
    # explicitly, not silently:
    #   nix flake update melete-src   # or mneme-src
    # To build a DIRTY worktree without committing, override for that one
    # rebuild — `path:` re-hashes the directory as it is on disk:
    #   nixos-rebuild switch --flake .#sakaki \
    #     --override-input melete-src path:/home/khoa/melete
    #
    # Only sakaki forces these (dx.melete/dx.mneme are false elsewhere, and
    # module args are lazy), so chiyo/osaka still evaluate fine without the
    # repos on disk — but `nix flake update` with no argument would try to
    # re-lock them, so run it on sakaki, or name the inputs you mean.
    melete-src = {
      url = "git+file:///home/khoa/melete";
      flake = false;
    };
    mneme-src = {
      url = "git+file:///home/khoa/mneme";
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
    # (hosts, hardware, secrets). git+file pins to Aoide's COMMITTED state
    # (main HEAD), so Aoide's in-flight working-tree edits never leak into
    # dxflake builds. The rev was hand-pinned because Aoide's worktree carried
    # an uncommitted diff at pin time; with ?rev= explicit, `nix flake update
    # aoide` is now a no-op. Advance by bumping ?rev= to Aoide's new committed
    # HEAD; drop ?rev= (back to plain `nix flake update aoide`) only once
    # Aoide's worktree is clean.
    aoide = {
      url = "git+file:///home/khoa/Aoide?rev=7fa52c8399779ed876ea0f0b1d512685a421d6e8";
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
        # osaka runs the Aoide doors (CLI + aoided + A2A) alongside her own
        # dx desktop — no facets, the dx rice keeps painting (dxflake's
        # shared dendrites are never shelved: chiyo still runs them).
        osaka = mkHost "osaka" true;
        # sakaki runs Aoide headless (CLI + aoided + the A2A door) for
        # federation testing; yomi-strix stays on the Aoide flake itself and
        # is NOT activated here — its dxflake config remains the plain rig.
        sakaki = mkHost "sakaki" true;
        yomi-strix = mkHost "yomi-strix" false;
      };
    };
}
