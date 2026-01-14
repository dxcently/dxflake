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
    };
    gh = {
      enable = true;
      gitCredentialHelper.enable = true;
    };
  };
}
