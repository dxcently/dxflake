#!/usr/bin/env bash
# Two halves, because the guard has two failure modes.
#
#   behaviour  runs THE SHIPPED SCRIPT against a stubbed hyprctl/systemctl/dbus
#              and asserts exactly which commands it issued. The instance lists
#              are transformations of instances.json — real output, captured off
#              a live hijack. See README.md.
#   source     renders every host's hyprland.conf out of the flake and asserts
#              home-manager's unguarded session lines are not in it. This is the
#              regression proper: the defect was a default coming back on, not
#              the script misbehaving.
#
#   ./tests/session-guard/run.sh            # both halves
#   ./tests/session-guard/run.sh behaviour
#   ./tests/session-guard/run.sh source
set -uo pipefail
cd "$(dirname "$0")" || exit 1
root=$(cd ../.. && pwd)
script=$root/modules/dendrites/compositor/hypr-session-import.sh

half="${1:-all}"
pass=0; fail=0
ok()   { printf '%-34s PASS%s\n' "$1" "${2:+  ($2)}"; pass=$((pass+1)); }
bad()  { printf '%-34s FAIL  %s\n' "$1" "$2"; fail=$((fail+1)); }
rule() { printf '%s\n' "------------------------------------------------------------"; }

PRIMARY=$(jq -r '.[0].instance' instances.json)
NESTED=$(jq -r '.[1].instance' instances.json)

# A pid that is definitely gone, so "the older instance crashed" is testable.
dead=$(cat /proc/sys/kernel/pid_max)
while [ -d "/proc/$dead" ]; do dead=$((dead-1)); done

# ── behaviour ────────────────────────────────────────────────────────────────
# The three command lines the guard may issue, named so a case reads as intent.
IMPORT='dbus-update-activation-environment --systemd --all
systemctl --user stop hyprland-session.target
systemctl --user start hyprland-session.target'
STOP='systemctl --user stop hyprland-session.target'
NOTHING=''

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
stub=$work/bin; mkdir -p "$stub"
# shellcheck disable=SC2016  # the stub body is written literally, not expanded here
for name in systemctl dbus-update-activation-environment; do
  printf '#!/usr/bin/env bash\nprintf "%%s %%s\\n" "%s" "$*" >> "$STUB_LOG"\n' "$name" > "$stub/$name"
done
cat > "$stub/hyprctl" <<'STUB'
#!/usr/bin/env bash
[ "${STUB_HYPRCTL_RC:-0}" = 0 ] || exit "$STUB_HYPRCTL_RC"
cat "$STUB_INSTANCES"
STUB
chmod +x "$stub"/*

# name  self  mode  instance-list (a jq program over instances.json, or a
#                   literal EMPTY / FAIL)  expected command log
behave() {
  local name=$1 self=$2 mode=$3 fixture=$4 want=$5 wantrc=${6:-0}
  local log=$work/log; : > "$log"
  local rc=0 env=()
  case $fixture in
    FAIL)  env=(STUB_HYPRCTL_RC=1 STUB_INSTANCES=/dev/null) ;;
    EMPTY) printf '' > "$work/inst"; env=("STUB_INSTANCES=$work/inst") ;;
    *)     jq "$fixture" instances.json > "$work/inst"; env=("STUB_INSTANCES=$work/inst") ;;
  esac
  env PATH="$stub:$PATH" STUB_LOG="$log" "${env[@]}" \
    HYPRLAND_INSTANCE_SIGNATURE="$self" \
    bash -o errexit -o nounset -o pipefail "$script" "$mode" 2>"$work/err"
  rc=$?
  local got; got=$(sed 's/  *$//' "$log")
  local noise; noise=$(grep -c "integer expected\\|unbound variable\\|syntax error" "$work/err" || true)
  if [ "$got" = "$want" ] && [ "$rc" -eq "$wantrc" ] && [ "$noise" = 0 ]; then
    ok "$name" "$([ -n "$want" ] && printf 'acted' || printf 'stood down')"
  else
    bad "$name" "rc=$rc (want $wantrc), shell errors=$noise"
    printf '%s\n' "    | want: ${want:-<nothing>}" "    | got:  ${got:-<nothing>}"
    sed 's/^/    | err: /' "$work/err"
  fi
}

# jq programs over the captured list. `live` is this runner's own pid, which is
# the only pid a test can be sure is in /proc.
both="map(.pid = $$)"
onlyPrimary="[.[0]] | map(.pid = $$)"
primaryDead="[(.[0] | .pid = $dead), (.[1] | .pid = $$)]"
primaryNoTime="[(.[0] | .time = null | .pid = $$), (.[1] | .pid = $$)]"

if [ "$half" = all ] || [ "$half" = behaviour ]; then
  printf '%-34s %s\n' "BEHAVIOUR" "RESULT"; rule
  # A login: nothing else is running, so the session is this instance's.
  behave loginSoleInstance      "$PRIMARY" start "$onlyPrimary"   "$IMPORT"
  # Still a login, with a nested instance already up. Ours started first.
  behave loginWithNestedAlready "$PRIMARY" start "$both"          "$IMPORT"
  # The hijack. An older live instance owns the session; stand down.
  behave nestedUnderLogin       "$NESTED"  start "$both"          "$NOTHING"
  # The older signature's process is gone — leftovers, not an owner.
  behave staleOlderInstance     "$NESTED"  start "$primaryDead"   "$IMPORT"
  # Fail-safe: an unanswerable question must never cost a login its session.
  behave hyprctlFails           "$NESTED"  start FAIL             "$IMPORT"
  behave hyprctlEmpty           "$NESTED"  start EMPTY            "$IMPORT"
  behave selfNotListed          "nosuchsig" start "$both"         "$IMPORT"
  behave malformedTime          "$NESTED"  start "$primaryNoTime" "$IMPORT"
  # exec-shutdown is the sharper edge: closing a nested window must not stop
  # the real session's target.
  behave stopFromNested         "$NESTED"  stop  "$both"          "$NOTHING"
  behave stopFromLogin          "$PRIMARY" stop  "$both"          "$STOP"
  behave unknownMode            "$PRIMARY" frob  "$onlyPrimary"   "$NOTHING" 2
  rule
fi

# ── source ───────────────────────────────────────────────────────────────────
# Hosts whose hyprland.conf is written by something dxflake does not own, and
# so cannot fix without becoming a second writer on the same leaf options (see
# modules/dendrites/aoide.nix's header for why that is worse than the bug).
# The exemption is not a mute: a host listed here that comes back CLEAN is a
# FAIL, because it means the upstream fix landed and this line should be gone.
exempt_chiyo="Aoide's compositor facet, not dxflake's dendrite — fix is Fable's, arrives by pin bump"

if [ "$half" = all ] || [ "$half" = source ]; then
  printf '%-34s %s\n' "SOURCE" "RESULT"; rule
  hosts=$(nix eval --impure --json "$root#nixosConfigurations" --apply builtins.attrNames 2>/dev/null | jq -r '.[]')
  for host in $hosts; do
    conf=$work/$host.conf
    if ! nix eval --raw --impure \
        "$root#nixosConfigurations.$host.config.home-manager.users.khoa.xdg.configFile.\"hypr/hyprland.conf\".text" \
        > "$conf" 2>"$work/err"; then
      # A host with no home-manager hyprland has nothing to regress.
      ok "$host" "no hyprland config"
      continue
    fi

    case $host in
      chiyo) exemption=$exempt_chiyo ;;
      *) exemption= ;;
    esac
    clean=yes; why=
    grep -q 'dbus-update-activation-environment' "$conf" && { clean=no; why="home-manager's unguarded exec-once"; }
    [ "$clean" = yes ] && grep -q '^exec-shutdown=systemctl' "$conf" && { clean=no; why="bare exec-shutdown stops the real target"; }
    [ "$clean" = yes ] && ! grep -q 'hypr-session-import start' "$conf" && { clean=no; why="session is never imported at all"; }
    if [ "$clean" = yes ]; then
      # Ordering: the only exec-once allowed ahead of the import is a plugin
      # load, which talks to Hyprland's IPC and needs no session environment.
      before=$(sed -n '/hypr-session-import start/q;/^exec-once=/p' "$conf" | grep -v 'hyprctl plugin load')
      [ -n "$before" ] && { clean=no; why="import runs after: $(printf '%s' "$before" | head -1)"; }
    fi
    [ "$clean" = yes ] && ! grep -q 'hypr-session-import stop' "$conf" && { clean=no; why="exec-shutdown guard is missing"; }

    if [ -n "$exemption" ]; then
      if [ "$clean" = yes ]; then
        bad "$host" "exempt but now CLEAN — delete exempt_$host"
      else
        printf '%-34s KNOWN %s\n' "$host" "$why"
        printf '%s\n' "    | $exemption"
      fi
    elif [ "$clean" = yes ]; then
      ok "$host" "guarded, import first"
    else
      bad "$host" "$why"
    fi
  done

  # The cases above exercise the .sh. This is what proves the binary the config
  # points at is that same file and not a copy that drifted.
  built=$(nix build --impure --no-link --print-out-paths --expr \
    "let f = builtins.getFlake \"$root\"; in import $root/modules/dendrites/compositor/session-import.nix {
       pkgs = f.inputs.nixpkgs.legacyPackages.\${builtins.currentSystem}; }" 2>/dev/null)
  if [ -z "$built" ]; then
    bad shippedBytesMatchSource "derivation did not build (shellcheck?)"
  else
    # writeShellApplication prepends a shebang, `set -o` lines and a PATH, and
    # appends a trailing newline. Everything between must be the source file.
    off=$(grep -nFx "$(head -1 "$script")" "$built/bin/hypr-session-import" | head -1 | cut -d: -f1)
    if [ -n "$off" ] && diff -q "$script" <(tail -n +"$off" "$built/bin/hypr-session-import" | sed '${/^$/d}') >/dev/null; then
      ok shippedBytesMatchSource "shellcheck-clean"
    else
      bad shippedBytesMatchSource "built script differs from hypr-session-import.sh"
    fi
  fi
  rule
fi

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
