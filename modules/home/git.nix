{
  pkgs,
  config,
  ...
}: {
  programs = {
    git = {
      enable = true;
      settings = {
        user.name = "dxcently";
        user.email = "dxcently@gmail.com";
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
