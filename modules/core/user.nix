{
  pkgs,
  inputs,
  username,
  host,
  theme,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager inputs.nix-colors.homeManagerModules.default];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs username host theme;
      inherit (inputs.nix-colors.lib-contrib {inherit pkgs;}) gtkThemeFromScheme;
    };
    users.${username} = {
      imports =
        if (host == "osaka")
        then [./../home/default.osaka.nix]
        else [./../home];
      home.username = "${username}";
      home.homeDirectory = "/home/${username}";
      home.stateVersion = "23.11";
      programs.home-manager.enable = true;
    };
    backupFileExtension = "backup";
  };

  colorScheme = inputs.nix-colors.colorSchemes."${theme}";

  users.users.${username} = {
    isNormalUser = true;
    description = "${username}";
    extraGroups = [
      "networkmanager"
      "wheel"
      "libvirtd"
      "audio"
      "video"
      "dialout"
    ];
    shell = pkgs.zsh;
  };
  nix.settings.allowed-users = ["${username}"];
}
