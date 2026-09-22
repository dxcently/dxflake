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
    # Only sakaki enables these (dendrites.melete / dendrites.mneme /
    # dendrites.eidolon are false elsewhere and module args are lazy), but the
    # inputs are fetched at LOCK time on whatever host runs `nix flake update`,
    # so run it as khoa.
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
    # both sit on v0.3.6 — but that is the failure to expect, and the fix is
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
    # (hosts, hardware, secrets). Every host fetches the same published Aoide
    # source, locked in flake.lock, without needing a local Aoide checkout.
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

      hostNames = [
        "chiyo"
        "osaka"
        "sakaki"
        "yomi-strix"
      ];

      hosts = lib.genAttrs hostNames (
        name:
        composition.mkNixosHost {
          inherit nixpkgs system;
          hostName = name;
          # Override records name the hosts they are confined to; the constructor
          # checks those names against this list so a typo fails loudly instead
          # of applying nowhere.
          knownHosts = hostNames;
          registry = import ./modules;
          hostModules = [ ./hosts/${name} ];
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
