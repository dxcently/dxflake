{
  pkgs,
  config,
  ...
}: {
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    #remove sudo requirement for yazi
    sudo.extraConfig = ''
      khoa ALL=(ALL) NOPASSWD: /bin/bash -c 'yy'
    '';
    pam.services.hyprlock = {};
  };
}
