{...}: {
  programs.mcfly = {
    enable = true;
    enableBashIntegration = false;
    keyScheme = "vim";
    fuzzySearchFactor = 2;
  };
}
