# rices/fugue/rice.nix — a flat mono counterpoint to sonata's marble.
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
        widgets = borrow "fugue";
      in
      {
        config = lib.mkDefault {
          strillix.layout.widgets = (rice.composeRice widgets).layout.widgets;
          strillix.theme.polarity = "dark";
          strillix.theme.palette = {
            bg = "#0d0f12";
            fg = "#e4e6eb";
            accent = "#3ddbd9";
            urgent = "#ff5f56";
            hot = "#c6f135";
          };
          strillix.theme.base16 = {
            base00 = "#0d0f12";
            base01 = "#14171c";
            base02 = "#1e232a";
            base03 = "#414a55";
            base04 = "#6f7b88";
            base05 = "#e4e6eb";
            base06 = "#f0f2f5";
            base07 = "#ffffff";
            base08 = "#ff5f56";
            base09 = "#ff9f45";
            base0A = "#ffd23f";
            base0B = "#c6f135";
            base0C = "#3ddbd9";
            base0D = "#4d9fff";
            base0E = "#c77dff";
            base0F = "#ff7eb6";
          };
          strillix.theme.bar = {
            bg = "#0d0f12";
            fg = "#e4e6eb";
            accent = "#3ddbd9";
          };
          strillix.theme.notif = {
            bg = "#0d0f12";
            fg = "#e4e6eb";
            urgent = "#ff5f56";
          };
          strillix.theme.window = {
            border = "#3ddbd9";
            borderInactive = "#1e232a";
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
