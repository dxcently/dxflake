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
    # Eidolon — same PRIVATE-repo, git+https, default-branch deal as melete/mneme
    # above. Bump with `nix flake update eidolon-src`, or override for a dirty
    # worktree the same way.
    #
    # It carries one more wrinkle: its own workspace patches `harnox` to a
    # sibling `../harnox` checkout (eidolon's Cargo.toml, and nix/eidolon.nix's
    # own comment), and eidolon's committed Cargo.lock was generated under that
    # patch — no `source` field for harnox, so Cargo expects the literal
    # directory to exist rather than fetching it. eidolon's own flake.nix
    # supplies that via a `harnox` input, but it names it `github:noah427/harnox`
    # — Nix's native GitHub fetcher, which (unlike `git+https:`) does NOT go
    # through git or its credential helper, and 404s on this private repo
    # without a nix.conf access-token this flake deliberately avoids
    # provisioning. So dxflake pins its own harnox-src instead, fetched the same
    # credentialed way, and pkgs/eidolon-package.nix hands it in directly rather
    # than consuming eidolon's flake outputs (which would re-introduce the
    # unauthenticated github: fetch as a transitive input).
    eidolon-src = {
      url = "git+https://github.com/noah427/eidolon";
      flake = false;
    };
    # Tracks harnox's default branch, always latest — NOT a tag pin. eidolon's
    # own Cargo.toml pins harnox by tag and bumps it independently of this
    # flake (caught live: harnox moved v0.3.5 -> v0.3.6 mid-write here), so
    # chasing that tag by hand here just drifts stale between bumps. `[patch]`
    # needs a version-compatible harnox for Cargo to accept the path
    # substitution — a mismatched checkout falls back to a real network fetch
    # instead of patching, which is silent and confusing — but eidolon's own
    # dev workflow already runs the same way, sibling checkout against
    # whatever tag Cargo.toml currently names, so tracking latest here mirrors
    # that rather than fighting it.
    harnox-src = {
      url = "git+https://github.com/noah427/harnox";
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
    # (hosts, hardware, secrets). Every host fetches the same published Aoide
    # source, locked in flake.lock, without needing a local Aoide checkout.
    aoide = {
      # No `&rev=` — a rev in the URL is a pin `nix flake update aoide`
      # cannot move, which is what made every Aoide bump a hand edit of this
      # file. The rev lives in flake.lock now, so `dxbump` re-locks it.
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
