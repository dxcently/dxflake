{username, config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.hyprland {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      home.file.".config/satty/config.toml".text = ''
        [general]
        fullscreen = false
        early-exit = true
        corner-roundness = 8
        initial-tool = "brush"
        copy-command = "wl-copy"
        annotation-size-factor = 1
        output-filename = "/home/khoa/Pictures/Screenshots/satty-%Y%m%d-%H%M%S.png"
        save-after-copy = false
        default-hide-toolbars = false
        default-fill-shapes = false
        primary-highlighter = "block"
        actions-on-enter = ["save-to-clipboard"]
        actions-on-escape = ["exit"]

        [font]
        family = "Ubuntu"
        style = "Regular"
      '';
    };
  };
}
