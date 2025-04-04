{
  pkgs,
  config,
  ...
}: let
  palette = config.colorScheme.palette;
in {
  # Configure Kitty
  programs.kitty = {
    enable = true;
    package = pkgs.kitty;
    font.name = "Lekton Nerd Font Mono";
    font.size = 12;
    settings = {
      scrollback_lines = 2000;
      wheel_scroll_min_lines = 1;
      confirm_os_window_close = 0;
      window_padding_width = 5;
      window_border_width = 1.5;
      background_opacity = 1;
      enable_audio_bell = false;
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
    };
    keybindings = {
      "alt+j" = "next_window";
      "alt+k" = "previous_window";
      "alt+h" = "previous_tab";
      "alt+l" = "next_tab";
      "alt+enter" = "new_window_with_cwd";
      "alt+q" = "close_window";
    };
    extraConfig = ''
      enabled_layouts fat:bias=80;full_size=1
      adjust_column_width -10
      foreground #${palette.base05}
      background #${palette.base00}
      color0  #${palette.base03}
      color1  #${palette.base08}
      color2  #${palette.base0C}
      color3  #${palette.base09}
      color4  #${palette.base0D}
      color5  #${palette.base0E}
      color6  #${palette.base0F}
      color7  #${palette.base06}
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
      cursor  #${palette.base07}
      cursor_text_color #${palette.base00}
      selection_foreground #${palette.base01}
      selection_background #${palette.base0D}
      url_color #${palette.base08}
      active_border_color #${palette.base0B}
      inactive_border_color #${palette.base07}
      bell_border_color #${palette.base0A}
      active_tab_foreground   #${palette.base00}
      active_tab_background   #${palette.base0A}
      inactive_tab_foreground #${palette.base0F}
      inactive_tab_background #${palette.base0B}
    '';
  };
}
