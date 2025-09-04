{
  pkgs,
  configs,
  ...
}: {
  programs.git = {
    enable = true;
    userName = "dxcently";
    userEmail = "dxcently@gmail.com";
  };
}
