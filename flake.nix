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
      url = "git+file:///home/khoa/Aoide?rev=002e848f7c323351ffb2c0d6488856586f8b4887";
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

      # Aoide's walked module tree + songbook and the package overlays its
      # modules expect ride EVERY host now (dendritic discipline: the module
      # is always in the tree, a flag decides whether it does anything —
      # AGENTS.md, root, "Everything is a plugin"). This used to be gated
      # behind a per-host `withAoide` bool on mkHost, which was the exact
      # anti-pattern that discipline exists to avoid: it gated the MODULE
      # SURFACE at the flake level instead of gating BEHAVIOUR at the host
      # level. Dropped after confirming every Aoide module that does
      # anything wraps its whole `config` in `lib.mkIf config.aoide.enable`
      # (or a narrower flag under it) — nucleus/options.nix is the one
      # exception, and it declares options + eval-clean defaults only, no
      # behaviour (its own header says so). So a host that never flips
      # `aoide.enable` gets the full option surface and zero behaviour
      # change; proven by yomi-strix's toplevel derivation hashing
      # byte-identical before and after this fold (it sets no aoide.* flags
      # at all — it manages its OWN Aoide integration from a separate flake
      # at ~/Aoide, see hosts/yomi-strix/default.nix).
      mkHost =
        name:
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
            ++ aoideModules
            ++ aoideSongbook
            ++ [
              inputs.disko.nixosModules.disko
              aoideSeam
              ./hosts/${name}
            ];
        };
    in
    {
      nixosConfigurations = {
        # Every host now carries the Aoide option surface; which flags a host
        # flips (aoide.enable, aoide.a2a.enable, aoide.facets.*, …) is a
        # hosts/<name>/default.nix decision, not a flake-level one. chiyo,
        # osaka and sakaki flip dx.aoide.enable (modules/dendrites/aoide.nix)
        # for the shared core; chiyo additionally flips the paint facets
        # directly (see its host file). yomi-strix sets no aoide.* flags here
        # at all — it manages its own Aoide integration from ~/Aoide's own
        # flake, kept byte-identical by this fold (see mkHost's comment).
        chiyo = mkHost "chiyo";
        osaka = mkHost "osaka";
        sakaki = mkHost "sakaki";
        yomi-strix = mkHost "yomi-strix";
      };
    };
}
