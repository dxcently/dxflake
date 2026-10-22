# rices/quodlibet/rice.nix — the borrowed form: sonata's shelf, with fugue's bar, notifications and ricemode.
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
      {
        lib,
        rice,
        borrow,
        ...
      }:
      let
        widgets = borrow "quodlibet";
      in
      {
        config = lib.mkDefault {
          strillix.layout.widgets = (rice.composeRice widgets).layout.widgets;
          strillix.theme.polarity = "dark";
          strillix.theme.palette = {
            bg = "#5f4694";
            fg = "#f6f0ff";
            accent = "#ff6fc8";
            urgent = "#ff4d6d";
            hot = "#4dffa0";
          };
          strillix.theme.base16 = {
            base00 = "#5f4694";
            base01 = "#52397f";
            base02 = "#452e6b";
            base03 = "#b3a3d6";
            base04 = "#d3c8ea";
            base05 = "#f6f0ff";
            base06 = "#fbf8ff";
            base07 = "#fffdff";
            base08 = "#ff4d6d";
            base09 = "#ff9440";
            base0A = "#ffe14d";
            base0B = "#4dffa0";
            base0C = "#66eaff";
            base0D = "#8fb4ff";
            base0E = "#ff6fc8";
            base0F = "#d6a3ff";
          };
          strillix.theme.bar = {
            bg = "#5f4694";
            fg = "#f6f0ff";
            accent = "#ff6fc8";
          };
          strillix.theme.notif = {
            bg = "#5f4694";
            fg = "#f6f0ff";
            urgent = "#ff4d6d";
          };
          strillix.theme.window = {
            border = "#ff6fc8";
            borderInactive = "#452e6b";
          };
          strillix.theme.wallpaper = null;
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
