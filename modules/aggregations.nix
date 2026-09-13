# modules/aggregations.nix — shared membership and the preferences that belong
# with it.
#
# Called twice from one table: once for the host's system scope, once inside
# every user's selection scope. A host says `aggregations.desktop.enable` for
# the machine and `users.khoa.aggregations.desktop.enable` for the person, and
# the table decides which lane each member rides. System selection and per-user
# selection stay separate — neither scope installs the other's lane.
#
# Everything here is evaluated in the FIRST pass, so it is either a selection or
# a deferred platform module. Membership uses mkDefault: a host's ordinary
# selection outranks it, and two aggregations that default the same option to
# different values collide rather than letting import order pick a winner.
scope:
{ lib, config, ... }:
let
  inherit (lib)
    mkIf
    mkOption
    mkDefault
    types
    ;

  # stylix rides base at the system scope on every host, including hosts that
  # leave `dx.stylix.enable` false: Aoide probes `options ? stylix`, so the
  # option tree has to exist even where nothing paints with it.
  table = {
    base = {
      description = "Shell, editor and prompt tooling every host carries.";
      system = [ "stylix" ];
      home = [
        "bash"
        "btop"
        "direnv"
        "git"
        "mcfly"
        "neovim"
        "nh"
        "starship"
        "yazi"
      ];
    };

    desktop = {
      description = "A graphical session: audio, fonts, input methods, portals, login.";
      system = [
        "desktop-hardware"
        "desktop-packages"
        "displaymanager"
        "fcitx5"
        "flatpak"
        "fonts"
        "kitty"
        "pipewire"
        "printing"
        "thunar"
        "xserver"
      ];
      home = [
        "composekey"
        "fastfetch"
        "floorp"
        "foliate"
        "gtk"
        "qt"
        "vesktop"
        "virtmanager"
      ];
      # Gaming and electron want a high mmap count; shared by every desktop. A
      # preference of the aggregation, deferred to the platform pass — it was
      # the one piece of config the old desktop/default.nix carried beside its
      # import list.
      nixos = {
        boot.kernel.sysctl."vm.max_map_count" = 2147483642;
      };
    };

    hyprland = {
      description = "The Hyprland compositor and the surfaces dxflake draws on it.";
      system = [
        "hyprland"
        "hyprland-packages"
      ];
      home = [
        "rofi"
        "satty"
        "waybar"
        "wlogout"
      ];
    };

    gaming = {
      description = "Steam, gamescope and the launchers.";
      system = [
        "aagl"
        "gaming-packages"
        "steam"
      ];
      home = [ ];
    };
  };

  # What one aggregation contributes to the scope it was instantiated for. The
  # deferred `nixos` preference exists only where a NixOS option tree does.
  contribution =
    a:
    {
      dendrites = lib.genAttrs a.${scope} (_: {
        enable = mkDefault true;
      });
    }
    // lib.optionalAttrs (scope == "system" && a ? nixos) { inherit (a) nixos; };
in
{
  options.aggregations = lib.mapAttrs (_: a: {
    enable = mkOption {
      type = types.bool;
      default = false;
      inherit (a) description;
    };
  }) table;

  config = lib.mkMerge (
    lib.mapAttrsToList (name: a: mkIf config.aggregations.${name}.enable (contribution a)) table
  );
}
