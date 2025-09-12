{
  pkgs,
  config,
  lib,
  ...
}: {
  # Configure Kitty
  programs.kitty = lib.mkForce {
    enable = true;
    package = pkgs.kitty;
    #font.name = "Lekton Nerd Font Mono";
    #font.size = 12;
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
    /*
    extraConfig = ''
      enabled_layouts fat:bias=80;full_size=1
      adjust_column_width -10
      foreground #${config.lib.stylix.colors.base01}
      background #${config.lib.stylix.colors.base00}
      color0  #${config.lib.stylix.colors.base00}
      color1  #${config.lib.stylix.colors.base01}
      color2  #${config.lib.stylix.colors.base02}
      color3  #${config.lib.stylix.colors.base03}
      color4  #${config.lib.stylix.colors.base04}
      color5  #${config.lib.stylix.colors.base05}
      color6  #${config.lib.stylix.colors.base06}
      color7  #${config.lib.stylix.colors.base07}
      color8  #${config.lib.stylix.colors.base08}
      color9  #${config.lib.stylix.colors.base09}
      color10 #${config.lib.stylix.colors.base0A}
      color11 #${config.lib.stylix.colors.base0B}
      color12 #${config.lib.stylix.colors.base0C}
      color13 #${config.lib.stylix.colors.base0D}
      color14 #${config.lib.stylix.colors.base0E}
      color15 #${config.lib.stylix.colors.base0F}
      cursor  #${config.lib.stylix.colors.base05}
      cursor_text_color #${config.lib.stylix.colors.base00}
      selection_foreground #${config.lib.stylix.colors.base01}
      selection_background #${config.lib.stylix.colors.base0D}
      url_color #${config.lib.stylix.colors.base0C}
      active_border_color #${config.lib.stylix.colors.base0A}
      inactive_border_color #${config.lib.stylix.colors.base09}
      bell_border_color #${config.lib.stylix.colors.base0A}
      active_tab_foreground   #${config.lib.stylix.colors.base01}
      active_tab_background   #${config.lib.stylix.colors.base00}
      inactive_tab_foreground #${config.lib.stylix.colors.base05}
      inactive_tab_background #${config.lib.stylix.colors.base04}
    '';
    */
  };
}
