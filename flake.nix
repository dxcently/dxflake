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
              discovered = builtins.filter (
                p:
                let
                  s = toString p;
                in
                nixpkgs.lib.hasSuffix ".nix" s && !(nixpkgs.lib.hasInfix "/_" s)
              ) (nixpkgs.lib.filesystem.listFilesRecursive ./modules);
            in
            discovered
            ++ [
              inputs.disko.nixosModules.disko
              ./hosts/${name}
            ];
        };
    in
    {
      nixosConfigurations = {
        chiyo = mkHost "chiyo";
        osaka = mkHost "osaka";
        sakaki = mkHost "sakaki";
        yomi-strix = mkHost "yomi-strix";
      };
    };
}
