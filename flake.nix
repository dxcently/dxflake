{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager/master";
    };
    nixpkgs_patched.url = "github:nixos/nixpkgs/468a37e6ba01c45c91460580f345d48ecdb5a4db";
    nix-colors.url = "github:misterio77/nix-colors";
    nvf.url = "github:notashelf/nvf";
    stylix.url = "github:danth/stylix";
    aagl = {
      url = "github:ezKEa/aagl-gtk-on-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    username = "khoa";
    theme = "black-metal-burzum";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      dxpad = nixpkgs.lib.nixosSystem {
        modules = [
          ./hosts/dxpad
          inputs.stylix.nixosModules.stylix
        ];
        specialArgs = {
          host = "dxpad";
          inherit username inputs theme system;
        };
      };
      dxeon = nixpkgs.lib.nixosSystem {
        specialArgs = {
          host = "dxeon";
          inherit username inputs system;
        };
        modules = [
          ./hosts/dxeon
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              users.${username} = import ./hosts/dxeon/home.nix;
              extraSpecialArgs = {
                inherit
                  username
                  inputs
                  theme
                  system
                  ;
                inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;
              };
              useGlobalPkgs = true;
              useUserPackages = true;
            };
          }
        ];
      };
    };
  };
}
