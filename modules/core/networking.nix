{
  pkgs,
  config,
  host,
  ...
}: {
  networking = {
    hostName = "${host}";
    networkmanager.enable = true;
  };

  environment.systemPackages = with pkgs; [networkmanagerapplet];
}
