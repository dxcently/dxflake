{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs_patched.url = "github:nixos/nixpkgs/468a37e6ba01c45c91460580f345d48ecdb5a4db";
    nix-colors.url = "github:misterio77/nix-colors";
    nvf.url = "github:notashelf/nvf";
  };
  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    username = "khoa";
    theme = "black-metal-immortal";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      dxpad = nixpkgs.lib.nixosSystem {
        specialArgs = {
          host = "dxpad";
          inherit username inputs system;
        };
        modules = [
          ./hosts/dxpad
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              users.${username} = import ./hosts/dxpad/home.nix;
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
