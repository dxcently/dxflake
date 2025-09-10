{
  pkgs,
  config,
  lib,
  ...
}: {
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
      "ctrl+shift+U" = "none"; #for vim's page up
    };
    extraConfig = lib.mkAfter ''
      enabled_layouts fat:bias=80;full_size=1
      adjust_column_width -10
      foreground @base05
      background @base00
      color0  @base03
      color1  @base08
      color2  @base0C
      color3  @base09
      color4  @base0D
      color5  @base0E
      color6  @base0F
      color7  @base06
      color8  @base04
      color9  @base08
      color10 @base0B
      color11 @base0A
      color12 @base0C
      color13 @base0E
      color14 @base0C
      color15 @base07
      color16 @base00
      color17 @base0F
      color18 @base0B
      color19 @base09
      color20 @base0D
      color21 @base0E
      color22 @base0C
      color23 @base06
      cursor  @base07
      cursor_text_color @base00
      selection_foreground @base01
      selection_background @base0D
      url_color @base08
      active_border_color @base0B
      inactive_border_color @base07
      bell_border_color @base0A
      active_tab_foreground   @base00
      active_tab_background   @base0A
      inactive_tab_foreground @base0F
      inactive_tab_background @base0B
    '';
  };
}
