{
  pkgs,
  inputs,
  username,
  host,
  ...
}: {
  imports = [inputs.home-manager.nixosModules.home-manager];
  home-manager = {
    useUserPackages = true;
    useGlobalPkgs = true;
    extraSpecialArgs = {
      inherit inputs username host;
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
  };
  nix.settings.allowed-users = ["${username}"];
}
