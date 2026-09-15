# The guarded replacement for home-manager's Hyprland session handoff.
#
# The whole argument lives in hypr-session-import.sh — read it there. This file
# only wraps it: `writeShellApplication` supplies the bash shebang and
# `set -euo pipefail`, runs shellcheck at build time, and puts the four tools
# the script calls on its PATH, so the store path is self-contained and a
# missing tool is a build error rather than a broken login.
#
# The script is a real file rather than an inline string so that
# tests/session-guard/run.sh can execute THE SHIPPED BYTES against stubbed
# hyprctl/systemctl, instead of a paraphrase of them.
{ pkgs }:
pkgs.writeShellApplication {
  name = "hypr-session-import";
  runtimeInputs = with pkgs; [
    hyprland
    jq
    dbus
    systemd
  ];
  text = builtins.readFile ./hypr-session-import.sh;
}
