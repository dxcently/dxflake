{
  pkgs,
  config,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "dxcently";
    userEmail = "dxcently@gmail.com";
    extraConfig = {
      credential = {
        helper = "!/run/current-system/sw/bin/gh auth git-credential";
        "https://github.com".username = "dxcently";
        credentialStore = "cache";
      };
    };
  };
}
