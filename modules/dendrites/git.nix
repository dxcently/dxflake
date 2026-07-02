{username, ...}: {
  home-manager.users.${username} = {
    pkgs,
    config,
    ...
  }: {
    programs = {
      git = {
        enable = true;
        lfs.enable = true;
        signing.format = null;
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
        gitCredentialHelper = {
          enable = true;
          hosts = ["https://github.com" "https://gist.github.com"];
        };
      };
    };
  };
}
