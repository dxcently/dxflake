{
  description = "fart";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager/master";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixpkgs_patched.url = "github:nixos/nixpkgs/468a37e6ba01c45c91460580f345d48ecdb5a4db";
    nix-colors.url = "github:misterio77/nix-colors";
    spicetify-nix.url = "github:the-argus/spicetify-nix";
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    /*
      hyprland.url = "github:hyprwm/Hyprland";
      hyprland-plugins = {
        url = "github:hyprwm/hyprland-plugins";
        inputs.hyprland.follows = "hyprland";
      };
    */
  };
  outputs =
    inputs@{
      nixpkgs,
      home-manager,
      spicetify-nix,
      ...
    }:
    let
      system = "x86_64-linux";

      # User Variables
      hostname = "dxflake";
      username = "khoa";
      gitUsername = "dxcently";
      gitEmail = "dxcently@gmail.com";
      theme = "sakura";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };
    in
    {
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
                inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
                inherit spicetify-nix;
              };
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.users.${username} = import ./home.nix;
            }
          ];
        };
      };
    };
}
