{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.waybar = {

    enable = true;
    systemd = {
      enable = false; # disable it,autostart it in hyprland conf
      target = "graphical-session.target";
    };
    style = ''
      * {
      font-family: "ShureTechMono Nerd Font";
      font-size: 12pt;
      font-weight: bold;
      border-radius: 0px;
      transition-property: background-color;
      transition-duration: 0.5s;
      }
      @keyframes blink_red {
      to {
      background-color: rgb(242, 143, 173);
      color: rgb(26, 24, 38);
      }
      }
      .warning, .critical, .urgent {
      animation-name: blink_red;
      animation-duration: 1s;
      animation-timing-function: linear;
      animation-iteration-count: infinite;
      animation-direction: alternate;
      }
      window#waybar {
      background-color: transparent;
      }
      window > box {
      margin-left: 5px;
      margin-right: 5px;
      margin-top: 5px;
      background-color: #191724;
      }
      #workspaces {
      padding-left: 0px;
      padding-right: 4px;
      }
      #workspaces button {
      padding-top: 5px;
      padding-bottom: 5px;
      padding-left: 6px;
      padding-right: 6px;
      color:#D8DEE9;
      }
      #workspaces button.active {
      background-color: #ebbcba;
      color: #191724;
      }
      #workspaces button.urgent {
      color: rgb(26, 24, 38);
      }
      #workspaces button:hover {
      background-color:#e0def4;
      color: #191724;
      }
      tooltip {
      /* background: rgb(250, 244, 252); */
      background: #3b4253;
      }
      tooltip label {
      color: #E4E8EF;
      }
      #custom-launcher {
      font-size: 20px;
      padding-left: 8px;
      padding-right: 6px;
      color: #ebbcba;
      }
      #mode, #clock, #memory, #temperature,#cpu,#custom-wall, #temperature, #backlight, #wireplumber, #network, #battery, #custom-powermenu, #custom-cava-internal {
      padding-left: 10px;
      padding-right: 10px;
      }
      #memory {
      color: #8EBBBA;
      }
      #cpu {
      color: #B38DAC;
      }
      #clock {
      color: #E4E8EF;
      }
      #custom-wall {
      color: #B38DAC;
      }
      #temperature {
      color: #80A0C0;
      }
      #backlight {
      color: #A2BD8B;
      }
      #wireplumber {
      color: #E9C98A;
      }
      #network {
      color: #99CC99;
      }

      #network.disconnected {
      color: #CCCCCC;
      }
      #battery.charging, #battery.full, #battery.discharging {
      color: #CF876F;
      }
      #battery.critical:not(.charging) {
      color: #D6DCE7;
      }
      #custom-powermenu {
      color: #eb6f92;
      }
      #tray {
      padding-right: 8px;
      padding-left: 10px;
      }
      #tray menu {
      background: #191724;
      color: #DEE2EA;
      }
      #custom-cava-internal{
      font-family: "Hack Nerd Font" ;
      }
    '';
    settings = [
      {
        "layer" = "top";
        "position" = "top";
        modules-left = [
          "custom/launcher"
          "hyprland/workspaces"
          "custom/wall"
        ];
        modules-center = [
          "clock"
          "hyprland/window"
        ];
        modules-right = [
          "wireplumber"
          "backlight"
          "memory"
          "cpu"
          "network"
          "temperature"
          "battery"
          "custom/powermenu"
          "tray"
        ];
        "custom/launcher" = {
          "format" = "󰫢 ";
          #"on-click" = "pkill rofi || ~/.config/rofi/launcher.sh";
          "tooltip" = false;
        };
        "hyprland/window" = {
          max-length = 25;
          separate-outputs = false;
          rewrite = {
            "" = "/ᐠ - ˕ -マ Ⳋ ⋆｡°✩♬ ♪";
          };
        };
        /*
          "custom/wall" = {
            "on-click" = ${sharedScripts.wallpaper_random}/bin/wallpaper_random";
            "on-click-middle" = "${sharedScripts.default_wall}/bin/default_wall";
            "on-click-right" = killall dynamic_wallpaper || ${sharedScripts.dynamic_wallpaper}/bin/dynamic_wallpaper &";
            "format" = " 󰠖 ";
            "tooltip" = false;
          };
        */
        "custom/cava-internal" = {
          "exec" = ""; # "sleep 1s && ${sharedScripts.cava-internal}/bin/cava-internal";
          "tooltip" = false;
        };
        "hyprland/workspaces" = {
          "format" = "{name}";
          "on-click" = "activate";
          "on-scroll-up" = "hyprctl dispatch workspace e+1";
          "on-scroll-down" = "hyprctl dispatch workspace e-1";
        };
        "backlight" = {
          "device" = "intel_backlight";
          "on-scroll-up" = "light -A 5";
          "on-scroll-down" = "light -U 5";
          "format" = "{icon} {percent}%";
          "format-icons" = [
            "󰃝"
            "󰃞"
            "󰃟"
            "󰃠"
          ];
        };
        "wireplumber" = {
          "scroll-step" = 1;
          "format" = "{icon} {volume}%";
          "format-muted" = "󰖁 Muted";
          "format-icons" = {
            "default" = [
              ""
              ""
              ""
            ];
          };
          "on-click" = "pavucontrol";
          "tooltip" = true;
        };
        "battery" = {
          "interval" = 10;
          "states" = {
            "warning" = 20;
            "critical" = 10;
          };
          "format" = "{icon} {capacity}%";
          "format-icons" = [
            "󰁺"
            "󰁻"
            "󰁼"
            "󰁽"
            "󰁾"
            "󰁿"
            "󰂀"
            "󰂁"
            "󰂂"
            "󰁹"
          ];
          "format-full" = "{icon} {capacity}%";
          "format-charging" = "󰂄 {capacity}%";
          "tooltip" = false;
        };
        "clock" = {
          "interval" = 1;
          "format" = "{:%I:%M %p  %A %b %d}";
          "tooltip" = true;
          # "tooltip-format"= "{=%A; %d %B %Y}\n<tt>{calendar}</tt>"
          "tooltip-format" = "上午：高数\n下午：Ps\n晚上：Golang\n<tt>{calendar}</tt>";
        };
        "memory" = {
          "interval" = 1;
          "format" = "󰍛 {percentage}%";
          "states" = {
            "warning" = 85;
          };
        };
        "cpu" = {
          "interval" = 1;
          "format" = "󰻠 {usage}%";
        };
        /*
          "mpd" = {
            "max-length" = 25;
            "format" = "<span foreground='#bb9af7'></span> {title}";
            "format-paused" = " {title}";
            "format-stopped" = "<span foreground='#bb9af7'></span>";
            "format-disconnected" = "";
            "on-click" = "mpc --quiet toggle";
            "on-click-right" = "mpc update; mpc ls | mpc add";
            "on-click-middle" = "kitty --class='ncmpcpp' ncmpcpp";
            "on-scroll-up" = "mpc --quiet prev";
            "on-scroll-down" = "mpc --quiet next";
            "smooth-scrolling-threshold" = 5;
            "tooltip-format" = "{title} - {artist} ({elapsedTime:%M:%S}/{totalTime:%H:%M:%S})";
          };
        */
        "network" = {
          "format-disconnected" = "󰯡 Disconnected";
          "format-ethernet" = " Wired";
          "format-linked" = "󰖪 (No IP)";
          "format-wifi" = "󰖩 ";
          "interval" = 1;
          "tooltip" = true;
          "tooltip-format" = "󰖩  {essid} ({ipaddr})";
          "on-click" = "nm-applet --indicator";
        };
        "temperature" = {
          #"critical-threshold"= 80;
          "tooltip" = false;
          "format" = " {temperatureC}°C";
        };
        "custom/powermenu" = {
          "format" = "";
          "on-click" = "wlogout";
          "tooltip" = false;
        };
        "tray" = {
          "icon-size" = 15;
          "spacing" = 5;
        };
      }
    ];
  };
}
