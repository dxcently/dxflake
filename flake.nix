{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    habit = {
      url = "github:dxcently/habit/v0.7.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
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
    claude-desktop-nix-flake = {
      url = "github:poeck/claude-desktop-nix-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ── The noah427 AI stack: Melete, Mneme, Eidolon ──────────────────────
    # All three are PRIVATE repos under noah427 and are fetched straight from
    # GitHub. No local checkout is load-bearing any more: ~/melete, ~/mneme and
    # ~/eidolon are dev worktrees, and what a host BUILDS is whatever master
    # says, re-locked on demand.
    #
    # harnox is deliberately NOT an input here. It is not a flake and nothing
    # installs it on its own: it reaches the build only as a git dependency in
    # eidolon's Cargo.lock, fetched at the rev that lock names (see eidolon-src
    # below). dxflake pins no harnox rev that could drift from that one.
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
    #   nix flake update melete-src mneme-src eidolon-src eidolon-plugins aoide
    # `dxbump` (modules/dendrites/bash.nix) runs exactly that, then switches.
    #
    # To build a DIRTY local worktree without pushing, override for that one
    # rebuild — `path:` re-hashes the directory as it is on disk:
    #   nh os switch -- --override-input melete-src path:/home/khoa/melete
    #
    # Only sakaki enables these (habit.dendrites.melete /
    # habit.dendrites.mneme / habit.dendrites.eidolon are unwritten, so null,
    # elsewhere and module args are lazy), but the inputs are fetched at LOCK time on
    # whatever host runs `nix flake update`, so run it as khoa.
    melete-src = {
      url = "git+https://github.com/noah427/melete.git?ref=master";
      flake = false;
    };
    mneme-src = {
      url = "git+https://github.com/noah427/mneme.git?ref=master";
      flake = false;
    };
    # Eidolon is built from source like Melete and Mneme, so it rides as a
    # `flake = false` source input and pkgs/eidolon-package.nix builds the
    # crate. Its workspace links harnox through a git source in Cargo.lock
    # (not a sibling `[patch]`), and importCargoLock fetches that with
    # builtins.fetchGit, pinned by the rev the lock names. So harnox is not an
    # input here, and dxflake pins no harnox rev: `nix flake update eidolon-src`
    # moves eidolon, and harnox moves only when eidolon's Cargo.lock does.
    eidolon-src = {
      url = "git+https://github.com/noah427/eidolon.git?ref=master";
      flake = false;
    };
    # Eidolon's plugins (github.com/dxcently/eidolon-plugins, PUBLIC): a flake
    # whose packages are the plugin daemons. `github:`, not git+https:, because
    # the repo needs no credential. The private noah427 repos above need the git
    # fetcher for theirs. Its nixpkgs follows ours so the daemons build against
    # the pin the hosts run. modules/dendrites/eidolon.nix reads its `rev` for
    # the plugin refs, so the plugin directory and the binaries are one commit.
    eidolon-plugins = {
      url = "github:dxcently/eidolon-plugins";
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
    # ROS 2 for modules/dendrites/ros.nix. No `follows` on purpose: ros.cachix
    # builds against the overlay's OWN nixpkgs pin, so following ours would turn
    # every ROS package into a local compile.
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";

    # ── Aoide (AoideOS) integration ────────────────────────────────────────
    # dxflake consumes Aoide as a flake input through its exports (nucleus
    # module, overlay, theme, rices, parts). Hosts are composed by
    # habit, which Aoide builds on too: its habit follows ours so one copy is in
    # the graph. Its nixpkgs follows ours as well, so Aoide's packages build
    # against the pin the hosts run. Stylix, Hyprland and Quickshell are Aoide's
    # inputs and reach the hosts through its exports; dxflake declares none.
    # The structure a host RUNS is Aoide's; dxflake's own tree stays the venue
    # (hosts, hardware, secrets). Every host fetches the same published Aoide
    # source, locked in flake.lock, without needing a local Aoide checkout.
    # snowglobe: disposable NixOS microVMs for agents. A local repo for now (no
    # remote), so only hosts built from osaka can resolve it until it is pushed.
    snowglobe = {
      url = "git+file:///home/khoa/snowglobe";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };
    aoide = {
      # No `&rev=` — see the noah427 block above: a rev in the URL is a
      # pin `nix flake update aoide` cannot move, which is what made every
      # Aoide bump a hand edit of this file. The rev lives in flake.lock now.
      url = "git+https://github.com/dxcently/Aoide.git?ref=main";
      inputs.habit.follows = "habit";
      inputs.nixpkgs.follows = "nixpkgs";
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

      composition = inputs.habit.lib.composition { inherit lib; };

      aoideLanes = {
        quickshell = inputs.aoide.nixosModules.quickshell;
        strillix = inputs.aoide.nixosModules.strillix;
        dunst = inputs.aoide.nixosModules.dunst;
        clipboard = inputs.aoide.nixosModules.clipboard;
        screenshot = inputs.aoide.nixosModules.screenshot;
        hyprland = inputs.aoide.nixosModules.hyprland;
        aoide-stylix = inputs.aoide.nixosModules.stylix;
        aoide-compositor = inputs.aoide.nixosModules.compositor;
        aoided = inputs.aoide.nixosModules.aoided;
        aoide-secrets = inputs.aoide.nixosModules.aoide-secrets;
        aoide-nix = inputs.aoide.nixosModules.aoide-nix;
        aoide-packages = inputs.aoide.nixosModules.aoide-packages;
        melete-adapter = inputs.aoide.nixosModules.melete-adapter;
      };

      registry = (inputs.habit.lib.catalogues { inherit lib; }).mergeRegistries [
        (import ./modules { parts = inputs.aoide.parts; } // { name = "dx"; })
        {
          name = "aoide";
          catalogue = aoideLanes;
        }
      ];

      # The rices: Aoide's book and dxflake's own, merged as one (Aoide's
      # `lib.rices.merge`). Its hook answers habit's three rice hooks; a rice
      # name both books define throws.
      riceHook =
        (inputs.aoide.lib.rices.merge {
          inherit lib;
          pkgs = nixpkgs.legacyPackages.${system};
          books = [
            inputs.aoide.ricesRoot
            ./rices
          ];
        }).hook
          { inherit registry; };

      hostNames = [
        "chiyo"
        "osaka"
        "sakaki"
        "yomi-strix"
      ];

      # A NixOS guest (container or microVM) composed from the same registry as the hosts.
      habitGuest =
        name: host:
        composition.mkNixosModules {
          hostName = name;
          inherit registry host;
          knownHosts = hostNames ++ [ name ];
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          specialArgs = { inherit username nixpkgs-stable inputs; };
        };

      hosts = lib.genAttrs hostNames (
        name:
        composition.mkNixosHost {
          inherit nixpkgs system;
          hostName = name;
          # Override records name the hosts they are confined to; the constructor
          # checks those names against this list so a typo fails loudly instead
          # of applying nowhere.
          knownHosts = hostNames;
          inherit (riceHook) registry;
          host = ./hosts/${name};
          overlays = [
            inputs.aoide.overlays.default
            # The Zen package has no nixpkgs attribute; the catalogue names it as
            # pkgs.zen-browser, so this is where pkgs learns it.
            (_final: prev: {
              zen-browser = inputs.zen-browser.packages.${prev.stdenv.hostPlatform.system}.default;
            })
          ];
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          extraModules = [
            inputs.aoide.nixosModules.nucleus
            inputs.disko.nixosModules.disko
          ];
          selectionModules = riceHook.selectionModules;
          extraModulesFor = riceHook.extraModulesFor;
          specialArgs = {
            inherit username nixpkgs-stable inputs habitGuest;
            resolveAoideTheme = (inputs.aoide.lib.theme { inherit lib; }).resolve;
          };
        }
      );
    in
    {
      nixosConfigurations = lib.mapAttrs (_: h: h.system) hosts;

      # What each host actually resolved: dendrites, providers, users, which
      # halves each applies and the file each came from. Derived from selection,
      # never maintained by hand — `nix eval --json .#inventory.osaka` is the
      # review surface.
      inventory = lib.mapAttrs (_: h: h.inventory) hosts;

      # The merged catalogue hosts are composed from, so other flakes (snowglobe
      # templates) can compose guests from the same dendrites instead of a copy.
      inherit registry;
    };
}
