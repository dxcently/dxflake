{
  pkgs,
  config,
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
    extraConfig = ''
      enabled_layouts fat:bias=80;full_size=1
      adjust_column_width -10
      foreground #${config.lib.stylix.colors.base05}
      background #${config.lib.stylix.colors.base00}
      color0  #${config.lib.stylix.colors.base03}
      color1  #${config.lib.stylix.colors.base08}
      color2  #${config.lib.stylix.colors.base0C}
      color3  #${config.lib.stylix.colors.base09}
      color4  #${config.lib.stylix.colors.base0D}
      color5  #${config.lib.stylix.colors.base0E}
      color6  #${config.lib.stylix.colors.base0F}
      color7  #${config.lib.stylix.colors.base06}
      color8  #${config.lib.stylix.colors.base04}
      color9  #${config.lib.stylix.colors.base08}
      color10 #${config.lib.stylix.colors.base0B}
      color11 #${config.lib.stylix.colors.base0A}
      color12 #${config.lib.stylix.colors.base0C}
      color13 #${config.lib.stylix.colors.base0E}
      color14 #${config.lib.stylix.colors.base0C}
      color15 #${config.lib.stylix.colors.base07}
      color16 #${config.lib.stylix.colors.base00}
      color17 #${config.lib.stylix.colors.base0F}
      color18 #${config.lib.stylix.colors.base0B}
      color19 #${config.lib.stylix.colors.base09}
      color20 #${config.lib.stylix.colors.base0D}
      color21 #${config.lib.stylix.colors.base0E}
      color22 #${config.lib.stylix.colors.base0C}
      color23 #${config.lib.stylix.colors.base06}
      cursor  #${config.lib.stylix.colors.base07}
      cursor_text_color #${config.lib.stylix.colors.base00}
      selection_foreground #${config.lib.stylix.colors.base01}
      selection_background #${config.lib.stylix.colors.base0D}
      url_color #${config.lib.stylix.colors.base08}
      active_border_color #${config.lib.stylix.colors.base0B}
      inactive_border_color #${config.lib.stylix.colors.base07}
      bell_border_color #${config.lib.stylix.colors.base0A}
      active_tab_foreground   #${config.lib.stylix.colors.base00}
      active_tab_background   #${config.lib.stylix.colors.base0A}
      inactive_tab_foreground #${config.lib.stylix.colors.base0F}
      inactive_tab_background #${config.lib.stylix.colors.base0B}
    '';
  };
}
