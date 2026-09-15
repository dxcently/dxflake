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
    # ── The noah427 AI stack: Melete, Mneme, harnox, Eidolon ──────────────
    # All four are PRIVATE repos under noah427 and are fetched straight from
    # GitHub. No local checkout is load-bearing any more: ~/melete, ~/mneme,
    # ~/harnox and ~/eidolon are dev worktrees, and what a host BUILDS is
    # whatever master says, re-locked on demand.
    #
    # `git+https:` and not `github:` — the tarball fetcher a `github:` URL
    # uses can only authenticate from a nix.conf `access-tokens` entry (a
    # secret in a world-readable file, and unset on every host here), while
    # the git fetcher shells out to git and so picks up khoa's gh credential
    # helper from ~/.config/git/config. Aoide below is fetched the same way
    # for the same reason. Consequence: evaluate as khoa (`nh os switch`),
    # never a bare `sudo nixos-rebuild` — root has no GitHub credentials.
    #
    # NO `rev=` IN ANY URL. A rev inside the URL is a pin `nix flake update`
    # cannot move, so every upstream commit would mean hand-editing this
    # file. With just `ref=master` the rev lives in flake.lock and one
    # command picks up new commits for the whole stack:
    #   nix flake update melete-src mneme-src harnox-src eidolon aoide
    # `dxbump` (modules/dendrites/bash.nix) runs exactly that, then switches.
    #
    # To build a DIRTY local worktree without pushing, override for that one
    # rebuild — `path:` re-hashes the directory as it is on disk:
    #   nh os switch -- --override-input melete-src path:/home/khoa/melete
    #
    # Only sakaki enables these (dx.melete/dx.mneme/dx.eidolon are false
    # elsewhere and module args are lazy), but the inputs are fetched at
    # LOCK time on whatever host runs `nix flake update`, so run it as khoa.
    melete-src = {
      url = "git+https://github.com/noah427/melete.git?ref=master";
      flake = false;
    };
    mneme-src = {
      url = "git+https://github.com/noah427/mneme.git?ref=master";
      flake = false;
    };
    # The shared Rust+LLM foundation under Melete/Mneme/Eidolon. No flake, no
    # binary — Melete and Mneme resolve it by exact rev from their own
    # Cargo.lock (builtins.fetchGit, see pkgs/melete-package.nix), so the one
    # thing this input is FOR is Eidolon: its flake declares harnox as
    # `github:noah427/harnox`, and that tarball fetcher 404s on a private repo
    # (it authenticates only from a nix.conf `access-tokens` entry, which no
    # host here sets). The `follows` on the eidolon input below swaps that
    # dead node for this one, which the git fetcher CAN authenticate. Verified
    # the hard way: `builtins.fetchTree { type = "github"; ... }` on this exact
    # rev returns HTTP 404 while the git+https fetch of it succeeds.
    #
    # Caveat that comes with the follows: Eidolon's Cargo.lock names an exact
    # harnox VERSION, so if harnox master ever runs ahead of the tag Eidolon
    # pins, this build fails on a stale lock until Eidolon bumps its tag. They
    # are edited together by design (Eidolon's Cargo.toml says so), and today
    # both sit on v0.3.4 — but that is the failure to expect, and the fix is
    # `nix flake update eidolon` once upstream catches up.
    harnox-src = {
      url = "git+https://github.com/noah427/harnox.git?ref=master";
      flake = false;
    };
    # Eidolon, unlike the other three, ships a real flake whose package
    # already does the awkward part (it reassembles the `../harnox` sibling
    # layout Cargo's `[patch]` table expects — nix/eidolon.nix in that repo).
    # So it rides as a FLAKE input and dxflake writes no packaging of its
    # own; modules/dendrites/eidolon.nix just installs
    # inputs.eidolon.packages.<system>.default.
    eidolon = {
      url = "git+https://github.com/noah427/eidolon.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
      # Its own `github:noah427/harnox` cannot authenticate — see harnox-src.
      inputs.harnox.follows = "harnox-src";
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
      # No `&rev=` — see the noah427 block above: a rev in the URL is a
      # pin `nix flake update aoide` cannot move, which is what made every
      # Aoide bump a hand edit of this file. The rev lives in flake.lock now.
      url = "git+https://github.com/dxcently/Aoide.git?ref=main";
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
            inherit username system nixpkgs-stable;
            resolveAoideLivery =
              (import (inputs.aoide + "/lib/livery.nix") {
                inherit (nixpkgs) lib;
              }).resolve;
            inputs = inputs // {
              aoide = inputs.aoide.inputs.aoide;
            };
          };
          modules =
            let
              discovered = [ ./modules ];
              aoideModules = [ (inputs.aoide + "/modules/default.nix") ];
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
