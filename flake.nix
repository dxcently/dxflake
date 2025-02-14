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
    theme = "sakura";

    pkgs = import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
    };
  in {
    nixosConfigurations = {
      dxpad = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/dxpad
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              users.${username} = import ./hosts/dxpad/home.nix;
              extraSpecialArgs = {
                inherit username inputs theme system;
                inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;
              };
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "l_backup";
            };
          }
        ];
        specialArgs = {
          host = "dxpad";
          inherit username inputs;
        };
      };
    };
  };

  /*
    nixosConfigurations = {
    "${hostname}" = nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit system;
        inherit inputs;
        inherit username;
        inherit hostname;
        inherit gitUsername;
        inherit gitEmail;
      };
      modules = [
        ./configuration.nix
        home-manager.nixosModules.home-manager
        {
          home-manager.extraSpecialArgs = {
            inherit username;
            inherit gitEmail;
            inherit inputs;
            inherit gitUsername;
            inherit theme;
            inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.${username} = import ./home.nix;
        }
      ];
    };
  };
  */
}
