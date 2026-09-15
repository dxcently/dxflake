# hypr-session-import — hand THIS Hyprland instance's environment to the
# systemd and D-Bus user managers, and own hyprland-session.target — but only
# when this instance is the one that owns the login session.
#
# WHAT IT REPLACES. home-manager's hyprland module, with `systemd.enable = true`,
# writes these two lines at the top of hyprland.conf, unconditionally:
#
#   exec-once = …/dbus-update-activation-environment --systemd --all \
#               && systemctl --user stop hyprland-session.target \
#               && systemctl --user start hyprland-session.target
#   exec-shutdown = systemctl --user stop hyprland-session.target
#
# On a login that is exactly right: it is the only thing that puts
# WAYLAND_DISPLAY / DISPLAY / HYPRLAND_INSTANCE_SIGNATURE into the user
# managers, and hyprland-session.target BindsTo graphical-session.target, so it
# is what brings waybar, the portals and every user service up at all.
#
# On a NESTED Hyprland — one launched from a terminal inside a running session,
# which loads the same config — it is a session hijack. The nested instance
# repoints the user manager at its own sockets, then stops and restarts the
# target, and every service on it follows the environment into the nested
# window. The `exec-shutdown` line is worse: closing the nested window stops
# the REAL session's target. Observed on this fleet; the nested instance
# exported the whole environment because dxflake passes `--all`.
#
# THE DISCRIMINATOR, AND WHAT WAS RULED OUT. Hyprland has no "am I nested"
# flag, and hyprlang has no conditionals, so the guard lives where Hyprland
# already runs a shell: exec-once and exec-shutdown are dispatched through
# `sh -c`. What it asks is Hyprland's own IPC — `hyprctl instances` — for a
# live instance that started BEFORE this one. That instance owns the session;
# this one does not.
#
# Two cheaper-looking signals were tested against the live fleet and rejected:
#
#   * the compositor's own launch environment (a nested Hyprland inherits
#     WAYLAND_DISPLAY, a login one does not). True, but unreadable: the login
#     path runs through a wrapper binary, which clears the dumpable flag, and
#     /proc/<pid>/environ is then root-only — the exact instance that must not
#     be misread is the one that cannot be read.
#   * `systemctl --user show-environment` already holding a WAYLAND_DISPLAY.
#     Unsafe in the other direction: a user manager that outlives a logout
#     keeps the stale value, so a genuine login would read as nested and come
#     up with no environment at all.
#
# FAILING SAFE. Every uncertain answer — no IPC, no jq, this instance missing
# from the instance list — is treated as "I am the session owner", so the
# import still happens. A guard that cannot tell must not be what breaks a
# login; the cost is that a nested instance on a broken IPC still hijacks.
mode=${1:-start}
self=${HYPRLAND_INSTANCE_SIGNATURE:-}

log() { printf 'hypr-session-import: %s\n' "$*" >&2; }

# The signature of a live instance older than this one, or empty.
owner=""
instances=""
if ! instances=$(hyprctl instances -j 2>/dev/null) || [ -z "$instances" ]; then
  log "hyprctl instances unavailable — treating this instance as the session owner"
  instances=""
fi

if [ -n "$instances" ]; then
  mine=$(printf '%s\n' "$instances" | jq -r --arg s "$self" '.[] | select(.instance == $s) | .time' 2>/dev/null || true)
  # Digits or nothing, here and in the loop. `[ x -lt y ]` against a non-number
  # is not an abort — the comparison sits in an `if` condition, which `set -e`
  # exempts — but it returns 2 and prints `[: null: integer expected` to the
  # session log on every startup. Deciding it explicitly says what the fallback
  # should be instead of inheriting it from a shell error.
  case $mine in
    "" | *[!0-9]*) mine="" ;;
  esac
  if [ -z "$mine" ]; then
    log "this instance is not in the instance list — treating it as the session owner"
  else
    while read -r sig started pid; do
      [ -n "$sig" ] || continue
      [ "$sig" != "$self" ] || continue
      case $started in
        "" | *[!0-9]*) continue ;;
      esac
      # A signature whose process is gone is a crashed session's leftovers, not
      # a live owner. hyprctl does not always reap those.
      [ -d "/proc/$pid" ] || continue
      if [ "$started" -lt "$mine" ]; then
        owner=$sig
        break
      fi
    done < <(printf '%s\n' "$instances" | jq -r '.[] | "\(.instance) \(.time) \(.pid)"' 2>/dev/null || true)
  fi
fi

if [ -n "$owner" ]; then
  log "nested inside $owner — leaving the session environment and hyprland-session.target alone"
  exit 0
fi

case $mode in
  start)
    # Parity with the home-manager line this replaces, `--all` included:
    # narrowing the variable set here would change what a NORMAL login exports.
    dbus-update-activation-environment --systemd --all
    systemctl --user stop hyprland-session.target
    systemctl --user start hyprland-session.target
    ;;
  stop)
    systemctl --user stop hyprland-session.target
    ;;
  *)
    log "unknown mode '$mode'; expected start or stop"
    exit 2
    ;;
esac
