{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
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
  };
  outputs = {
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    username = "khoa";
  in {
    nixosConfigurations = {
      chiyo = nixpkgs.lib.nixosSystem {
        modules = [./hosts/chiyo];
        specialArgs = {
          host = "chiyo";
          inherit username inputs system nixpkgs-stable;
        };
      };
      osaka = nixpkgs.lib.nixosSystem {
        specialArgs = {
          host = "osaka";
          inherit username inputs system nixpkgs-stable;
        };
        modules = [./hosts/osaka];
      };
    };
  };
}
