{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
    habit = {
      url = "github:dxcently/habit/v1";
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
    #   nix flake update melete-src mneme-src eidolon aoide
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
    # Eidolon, unlike the other three, ships a real flake whose package
    # already does the awkward part (it reassembles the `../harnox` sibling
    # layout Cargo's `[patch]` table expects — nix/eidolon.nix in that repo).
    # So it rides as a FLAKE input and dxflake writes no packaging of its
    # own; modules/dendrites/eidolon.nix just installs
    # inputs.eidolon.packages.<system>.default.
    eidolon = {
      url = "git+https://github.com/noah427/eidolon.git?ref=master";
      inputs.nixpkgs.follows = "nixpkgs";
      # Its harnox input is `github:` (private, tarball fetcher): it reads
      # the token bash.nix exports into NIX_CONFIG from khoa's gh login.
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
    # module, overlay, livery, catalogue, songbook). Hosts are composed by
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
        lyra = inputs.aoide.nixosModules.lyra;
        dunst = inputs.aoide.nixosModules.dunst;
        clipboard = inputs.aoide.nixosModules.clipboard;
        screenshot = inputs.aoide.nixosModules.screenshot;
        hyprland = inputs.aoide.nixosModules.hyprland;
        aoide-stylix = inputs.aoide.nixosModules.stylix;
        aoide-compositor = inputs.aoide.nixosModules.compositor;
      };

      registry = (inputs.habit.lib.catalogues { inherit lib; }).mergeRegistries [
        (import ./modules // { name = "dx"; })
        {
          name = "aoide";
          catalogue = aoideLanes;
        }
      ];

      songbookDir = inputs.aoide.songbookRoot;
      songbook = inputs.aoide.lib.songbook {
        inherit lib;
        songbook = songbookDir;
      };

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
          inherit registry;
          hostModules = [ ./hosts/${name} ];
          nucleus = {
            imports = [
              inputs.aoide.nixosModules.nucleus
              ./modules/nucleus
            ];
          };
          overlays = [ inputs.aoide.overlays.default ];
          homeManagerModule = inputs.home-manager.nixosModules.home-manager;
          extraModules = [ inputs.disko.nixosModules.disko ];
          selectionModules = [ songbook.selectionModule ];
          extraModulesFor =
            sel:
            let
              song = songbook.check {
                inherit (sel) song;
                lyra = sel.dendrites.lyra.enable;
              };
            in
            songbook.songModules song
            ++ [
              {
                _module.args = {
                  inherit (songbook) song borrow;
                  songbook = songbookDir;
                };
                aoide.song = song.declared;
                aoide.songbook.builtIn = songbook.builtIn song;
              }
            ];
          specialArgs = {
            inherit username nixpkgs-stable inputs;
            resolveAoideLivery = (inputs.aoide.lib.livery { inherit lib; }).resolve;
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

      # The merged catalogue hosts are composed from, so other flakes (snowglobe
      # templates) can compose guests from the same dendrites instead of a copy.
      inherit registry;
    };
}
