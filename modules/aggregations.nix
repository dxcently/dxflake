# modules/aggregations.nix — shared membership and the preferences that belong
# with it.
#
# An aggregation is evaluated in the FIRST pass, so everything here is either a
# selection or a deferred platform module. Membership uses mkDefault: a host's
# ordinary selection outranks it, and two aggregations that default the same
# option to different values collide rather than letting import order pick a
# winner.
{ lib, config, ... }:
let
  inherit (lib)
    mkIf
    mkOption
    mkDefault
    types
    ;

  aggregation =
    name: description:
    mkOption {
      type = types.bool;
      default = false;
      inherit description;
    };

  # Membership shorthand: these dendrites ride this aggregation at the system
  # scope, each overridable by the host that disagrees.
  members = names: {
    dendrites = lib.genAttrs names (_: {
      enable = mkDefault true;
    });
  };
in
{
  options.aggregations = {
    base.enable = aggregation "base" "Shell, editor and prompt tooling every host carries.";
    desktop.enable = aggregation "desktop" "A graphical session: audio, fonts, input methods, portals, login.";
    hyprland.enable = aggregation "hyprland" "The Hyprland compositor and the surfaces dxflake draws on it.";
    gaming.enable = aggregation "gaming" "Steam, gamescope and the launchers.";
  };

  config = lib.mkMerge [
    # stylix rides base on every host, including hosts that leave
    # `dx.stylix.enable` false: Aoide probes `options ? stylix`, so the option
    # tree has to exist even where nothing paints with it.
    (mkIf config.aggregations.base.enable (members [
      "bash"
      "btop"
      "direnv"
      "git"
      "mcfly"
      "neovim"
      "nh"
      "starship"
      "stylix"
      "yazi"
    ]))

    (mkIf config.aggregations.desktop.enable (
      (members [
        "composekey"
        "desktop-hardware"
        "desktop-packages"
        "displaymanager"
        "fastfetch"
        "fcitx5"
        "flatpak"
        "floorp"
        "foliate"
        "fonts"
        "gtk"
        "kitty"
        "pipewire"
        "printing"
        "qt"
        "thunar"
        "vesktop"
        "virtmanager"
        "xserver"
      ])
      // {
        # Gaming and electron want a high mmap count; shared by every desktop.
        # A preference of the aggregation, deferred to the platform pass — it
        # was the one piece of config the old desktop/default.nix carried
        # beside its import list.
        nixos = {
          boot.kernel.sysctl."vm.max_map_count" = 2147483642;
        };
      }
    ))

    (mkIf config.aggregations.hyprland.enable (members [
      "hyprland"
      "hyprland-packages"
      "rofi"
      "satty"
      "waybar"
      "wlogout"
    ]))

    (mkIf config.aggregations.gaming.enable (members [
      "aagl"
      "gaming-packages"
      "steam"
    ]))
  ];
}
