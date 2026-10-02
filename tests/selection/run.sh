#!/usr/bin/env bash
# Runs every case over dxflake's real registry and checks it against its
# expectation. Composition itself is habit's and is tested there. A negative
# case must fail AND say something useful: the runner greps the real stderr, so
# a vague error is a failing test, not a passing one.
#
#   ./tests/selection/run.sh            # all cases
#   ./tests/selection/run.sh realRegistryLanesImport
set -uo pipefail
cd "$(dirname "$0")" || exit 1
root=$(cd ../.. && pwd)

# lib and habit come from the flake's own lock, so the cases run against the lib
# every host evaluates with and the habit every host is built by.
rev=$(jq -r '.nodes.nixpkgs.locked.rev' "$root/flake.lock")
lib="(builtins.getFlake \"github:nixos/nixpkgs/$rev\").lib"
habitRev=$(jq -r '.nodes.habit.locked.rev // "v1"' "$root/flake.lock")
habit="(builtins.getFlake \"github:dxcently/habit/$habitRev\")"

# case                              expect  substring the error must contain
cases=$(cat <<'EOF'
realRegistryResolvesSakaki          ok      "aoide,autologin,caddy,claude-code,cloudflared,eidolon,immich,jellyfin,kimi-cli,melete,mneme,nas-mounts,slskd,stylix,syncthing,transmission"
realRegistryLanesImport             ok      true
realRegistryInventory               ok      "base"
EOF
)

only="${1:-}"
pass=0; fail=0
printf '%-42s %s\n' "CASE" "RESULT"
printf '%s\n' "------------------------------------------------------------"
while read -r name expect want; do
  [ -z "$name" ] && continue
  [ -n "$only" ] && [ "$only" != "$name" ] && continue
  out=$(nix eval --impure --json --show-trace \
          --expr "(import ./cases.nix { lib = $lib; habit = $habit; }).$name" 2>&1)
  rc=$?
  if [ "$expect" = ok ]; then
    if [ $rc -eq 0 ] && [ "$(printf '%s' "$out" | tail -1)" = "$want" ]; then
      printf '%-42s PASS\n' "$name"; pass=$((pass+1))
    else
      printf '%-42s FAIL (want %s, rc=%s)\n' "$name" "$want" "$rc"
      printf '%s\n' "$out" | tail -6 | sed 's/^/    | /'
      fail=$((fail+1))
    fi
  else
    if [ $rc -ne 0 ] && printf '%s' "$out" | grep -qF -- "$want"; then
      printf '%-42s PASS  (%s)\n' "$name" "$want"; pass=$((pass+1))
    else
      printf '%-42s FAIL (error missing %s, rc=%s)\n' "$name" "$want" "$rc"
      printf '%s\n' "$out" | grep -v '^ *$' | tail -8 | sed 's/^/    | /'
      fail=$((fail+1))
    fi
  fi
done <<< "$cases"

printf '%s\n' "------------------------------------------------------------"
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
