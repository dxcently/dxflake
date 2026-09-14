# The desktop group — a graphical session.
#
# A selection module: imported in pass one from ../default.nix, into both
# scopes. It never imports the files beside it; it names them by catalogue
# name, and pass two imports whichever the selection kept. Membership is
# mkDefault, so a host's ordinary selection outranks it.
{
  lib,
  config,
  scope,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    mkDefault
    types
    ;

  members = names: {
    dendrites = lib.genAttrs names (_: {
      enable = mkDefault true;
    });
  };
in
{
  options.aggregation.desktop.enable = mkOption {
    type = types.bool;
    default = false;
    description = "A graphical session: audio, fonts, input methods, portals, login.";
  };

  config = mkIf config.aggregation.desktop.enable (
    if scope == "system" then
      members [
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
      ]
      // {
        # Gaming and electron want a high mmap count; shared by every desktop.
        # A preference of the group, deferred to the platform pass — it is the
        # one piece of config the old desktop/default.nix carried beside its
        # import list, and it comes back here with the file.
        nixos = {
          boot.kernel.sysctl."vm.max_map_count" = 2147483642;
        };
      }
    else
      members [
        "composekey"
        "fastfetch"
        "floorp"
        "foliate"
        "gtk"
        "qt"
        "vesktop"
        "virtmanager"
      ]
  );
}
