{
  pkgs,
  config,
  ...
}: {
  programs = {
    git = {
      enable = true;
      userName = "dxcently";
      userEmail = "dxcently@gmail.com";
      extraConfig = {
        init.defaultBranch = "main";
        safe.directory = [
          "/etc/nixos"
          "/home/khoa/dxflake"
        ];
      };
    };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
  };
}
