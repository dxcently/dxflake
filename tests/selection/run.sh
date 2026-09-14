#!/usr/bin/env bash
# Runs every selection case and checks it against its expectation. A negative
# case must fail AND say something useful: the runner greps the real stderr, so
# a vague error is a failing test, not a passing one.
#
#   ./tests/selection/run.sh            # all cases
#   ./tests/selection/run.sh unknownProvider
set -uo pipefail
cd "$(dirname "$0")" || exit 1
root=$(cd ../.. && pwd)

# lib comes from the flake's own locked nixpkgs, so the schema is tested
# against the lib every host evaluates with.
rev=$(jq -r '.nodes.nixpkgs.locked.rev' "$root/flake.lock")
lib="(builtins.getFlake \"github:nixos/nixpkgs/$rev\").lib"

# case                              expect  substring the error must contain
cases=$(cat <<'EOF'
disabledIsInert                     ok      "fixture"
unselectedProviderIsInert           ok      "dunst"
unselectedAggregationIsInert        ok      "fixture"
missingProvider                     throws  chose no provider; available providers: dunst, herald, landmine, mako
unknownProvider                     throws  has no provider 'nope'; available providers: dunst, herald, landmine, mako
providerOnSingleImpl                throws  single implementation and takes no provider (got 'mako')
systemScopeWantsHomeOnlyProvider    throws  'notifications/mako' is selected for the system but exposes no nixos lane; it supports: homeManager
systemScopeWantsHomeOnlyDendrite    throws  'homeonly' is selected for the system but exposes no nixos lane; it supports: homeManager
homeScopeWantsSystemOnlyDendrite    throws  'systemonly' is selected by user 'alice' but exposes no homeManager lane; it supports: nixos
unknownDendrite                     throws  does not exist
unknownAggregation                  throws  does not exist
unknownAggregationSelector          throws  aggregation.workstation.compositor
aggregationProviderSelector         ok      "herald"
hostOverridesAggregationProvider    ok      "herald"
aggregationsMergeOnSharedDendrite   ok      true
conflictingAggregationProviders     throws  has conflicting definition values
hostDisablesAggregationMember       ok      false
aggregationRidesPlatformSettings    ok      "workstation-fixture"
userAggregationContributesHomeMembers ok    true
userOverridesAggregationProvider    ok      "mako"
twoUserScopes                       ok      "mako+dunst"
scopesDoNotLeak                     ok      true
homeSelectionWithoutHomeManager     throws  homeManager.enable = false but selects home dendrites: notifications
homeManagerAbsent                   ok      true
EOF
)

only="${1:-}"
pass=0; fail=0
printf '%-34s %s\n' "CASE" "RESULT"
printf '%s\n' "------------------------------------------------------------"
while read -r name expect want; do
  [ -z "$name" ] && continue
  [ -n "$only" ] && [ "$only" != "$name" ] && continue
  out=$(nix eval --impure --json --show-trace \
          --expr "(import ./cases.nix { lib = $lib; }).$name" 2>&1)
  rc=$?
  if [ "$expect" = ok ]; then
    if [ $rc -eq 0 ] && [ "$(printf '%s' "$out" | tail -1)" = "$want" ]; then
      printf '%-34s PASS\n' "$name"; pass=$((pass+1))
    else
      printf '%-34s FAIL (want %s, rc=%s)\n' "$name" "$want" "$rc"
      printf '%s\n' "$out" | tail -6 | sed 's/^/    | /'
      fail=$((fail+1))
    fi
  else
    if [ $rc -ne 0 ] && printf '%s' "$out" | grep -qF -- "$want"; then
      printf '%-34s PASS  (%s)\n' "$name" "$want"; pass=$((pass+1))
    else
      printf '%-34s FAIL (error missing %s, rc=%s)\n' "$name" "$want" "$rc"
      printf '%s\n' "$out" | grep -v '^ *$' | tail -8 | sed 's/^/    | /'
      fail=$((fail+1))
    fi
  fi
done <<< "$cases"

printf '%s\n' "------------------------------------------------------------"
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
