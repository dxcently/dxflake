{
  username,
  ...
}: {
  security = {
    polkit.enable = true;
    rtkit.enable = true;
    #remove sudo requirement for yazi
    sudo.extraConfig = ''
      ${username} ALL=(ALL) NOPASSWD: /bin/bash -c 'yy'
    '';
  };
}
