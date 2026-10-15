# example-host.nix — a machine.
#
# Copy to:  hosts/<host>/default.nix, beside a generated hardware.nix
# Then:     add "<host>" to the host list in flake.nix. That is the only edit
#           flake.nix ever takes.
# Replace:  <host>, the selection, the user, the platform settings below, and
#           the stateVersion, which is the release you first install.
# Every host selects `core` and `network`, the floor it carries; a copy keeps
# both.
#           `./hardware.nix` is a placeholder — generate your own with
#           `nixos-generate-config`; the hardware in this tree's hosts is
#           specific to those machines.
#
# A host file is ONE module. Its `habit.*` keys are the SELECTION and everything
# else in it is this machine's own platform settings. It names no module file;
# nothing outside modules/default.nix does. Write `habit.*` here and nowhere
# else: a file this host imports cannot select anything, and the platform
# evaluation refuses one that tries.
{ pkgs, ... }:
{
  # ── Aggregations ─────────────────────────────────────────────────────────
  # A group's name, and — where the group owns a provider-bearing capability —
  # which implementation answers HERE. That selector lives on the group that
  # owns the capability, so a host says what it runs in one place and needs no
  # separate `habit.dendrites.*` override to do it.
  habit.aggregation = {
    core.enable = true;
    network.enable = true;
    base.enable = true;

    workspace = {
      enable = true;
      compositor.provider = "hyprland"; # the group has no default; say it here
    };
  };

  # ── Lone capabilities ────────────────────────────────────────────────────
  # Anything this machine wants that no group speaks for. `enable = false`
  # outranks a group's membership, which is how a host opts out of one member
  # without giving up the group.
  habit.dendrites = {
    exampletool.enable = true;
    examplebar.enable = false; # the workspace group wants it; this host does not
  };

  # ── People ───────────────────────────────────────────────────────────────
  # One shared definition, attached — never copied. `home.enable = false`
  # creates the account and imports no Home Manager module at all; asking for a
  # home capability with the home off is a configuration error, not a no-op.
  habit.users.exampleuser = {
    definition = ../../users/exampleuser.nix;
    home.enable = true;

    # The person, not the machine: this selects the group's HOME half, and the
    # provider choices that half owns — the group defaults to mako.
    aggregation.workspace = {
      enable = true;
      notifications.provider = "dunst";
    };

    dendrites.exampletool.enable = true; # its home half, on top of the group's

    # Optional. This person's extra home settings on this machine only.
    home.config =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.ripgrep ];
      };
  };

  # ── This machine ─────────────────────────────────────────────────────────
  # The rest of the module is ordinary NixOS configuration, evaluated by the
  # platform and by nothing before it: hardware imports, the `dx.*` knobs for
  # what genuinely varies, host-only overlays and packages. Nothing here can
  # influence selection, which is what keeps the two passes from chasing each
  # other.
  imports = [ ./hardware.nix ];
  networking.hostName = "examplehost";
  environment.systemPackages = [ pkgs.filezilla ];

  # Pins stateful-data formats from the first install; do not change it.
  system.stateVersion = "25.11";
}
