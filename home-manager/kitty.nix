{ pkgs, config, ... }:

let
  palette = config.colorScheme.palette;
in
{
  # Configure Kitty
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    font.name = "ShureTechMono Nerd Font";
    font.size = 12;
    settings = {
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;
      window_padding_width = 6;
      confirm_os_window_close = 0;
      background_opacity = "0.78";
    };
    extraConfig = ''
      foreground #${palette.base05}
      background #${palette.base00}
      color0  #${palette.base03}
      color1  #${palette.base0A}
      color2  #${palette.base08}
      color3  #${palette.base09}
      color4  #${palette.base05}
      color5  #${palette.base0B}
      color6  #${palette.base0C}
      color7  #${palette.base0D}
      color8  #${palette.base04}
      color9  #${palette.base08}
      color10 #${palette.base0B}
      color11 #${palette.base0A}
      color12 #${palette.base0C}
      color13 #${palette.base0E}
      color14 #${palette.base0C}
      color15 #${palette.base07}
      color16 #${palette.base00}
      color17 #${palette.base0F}
      color18 #${palette.base0B}
      color19 #${palette.base09}
      color20 #${palette.base0D}
      color21 #${palette.base0E}
      color22 #${palette.base0C}
      color23 #${palette.base06}
      cursor  #${palette.base04}
      cursor_text_color #${palette.base00}
      selection_foreground #${palette.base01}
      selection_background #${palette.base03}
      url_color #${palette.base0C}
      active_border_color #${palette.base04}
      inactive_border_color #${palette.base00}
      bell_border_color #${palette.base03}
      tab_bar_style fade
      tab_fade 1
      active_tab_foreground   #${palette.base04}
      active_tab_background   #${palette.base00}
      active_tab_font_style   bold
      inactive_tab_foreground #${palette.base07}
      inactive_tab_background #${palette.base08}
      inactive_tab_font_style bold
      tab_bar_background #${palette.base00}
    '';
  };
}
