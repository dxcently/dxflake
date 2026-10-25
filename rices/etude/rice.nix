# rices/etude/rice.nix — a throwaway practice piece for the declared widget-type registry.
#
# HOST-AGNOSTIC DISCIPLINE (CONTRACTS.md §5): a rice sets ONLY strillix.theme
# and strillix.layout. All values are literal nix (no rice/ runtime reads).
{
  system = {
    providers = {
      bar = "strillix";
      launcher = "strillix";
      powermenu = "strillix";
      notifications = "strillix";
      wallpaper = "strillix";
      dock = "strillix";
      calendar = "strillix";
      switcher = "strillix";
      lock = "strillix";
      greeter = "strillix";
    };
    module =
      { lib, ... }:
      {
        config = lib.mkDefault {
          strillix.theme.polarity = "dark";
          strillix.theme.palette = {
            bg = "#12121c";
            fg = "#e6e6f0";
            accent = "#7c5cff";
            urgent = "#ff5c7c";
          };
          strillix.theme.bar = {
            bg = "#12121c";
            fg = "#e6e6f0";
            accent = "#7c5cff";
          };
          strillix.theme.notif = {
            bg = "#12121c";
            fg = "#e6e6f0";
            urgent = "#ff5c7c";
          };
          strillix.theme.window = {
            border = "#7c5cff";
            borderInactive = "#12121c";
          };
          strillix.theme.wallpaper = null;
          strillix.layout.widgets.demo = {
            kind = "surface";
            namespace = "aoide-etude-demo";
            layer = "overlay";
            shortcut = "aoide:etude-demo";
            blur = true;
          };
        };
      };
  };
  home = {
    members = [ "strillix" ];
    module = {
      rice.hyprland.conf = ./hyprland.conf;
    };
  };
}
