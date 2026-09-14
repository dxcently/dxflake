#!/usr/bin/env bash
# The rice is a look with one source, palette.nix, read by three places: the
# generated livery.json, the Stylix scheme that actually paints GTK and Qt, and
# a stylesheet template that two different renderers can fill. Each place can
# drift from the source, and drift in a look is silent — nothing fails to
# evaluate, the desktop just comes up slightly wrong. So each one gets an
# assertion.
#
#   ./tests/rice/run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit 1
root=$(cd ../.. && pwd)
song=$root/songbook/transience

pass=0; fail=0
ok()   { printf '%-34s PASS%s\n' "$1" "${2:+  ($2)}"; pass=$((pass+1)); }
bad()  { printf '%-34s FAIL  %s\n' "$1" "$2"; fail=$((fail+1)); }
skip() { printf '%-34s KNOWN %s\n' "$1" "$2"; }
rule() { printf '%s\n' "------------------------------------------------------------"; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

# Never the live root: lyra reads AOIDE_ROOT for its stage, and nothing here is
# allowed near it. Every lyra call below is also given an explicit file path, so
# the staged rice is not even consulted.
export AOIDE_ROOT=$work/aoide-root
mkdir -p "$AOIDE_ROOT"

# ── the record matches the source ────────────────────────────────────────────
# livery.json is generated from palette.nix, not authored — if a hex is ever
# hand-edited in the JSON without touching palette.nix, this is what catches
# the checked-in file going stale.
if command -v nix >/dev/null 2>&1 &&
  nix eval --json --file "$song/palette.nix" livery 2>/dev/null | jq . >"$work/livery.json" 2>/dev/null &&
  [ -s "$work/livery.json" ]; then
  if diff -q "$work/livery.json" "$song/livery.json" >/dev/null 2>&1; then
    ok liveryJsonIsGenerated "matches palette.nix"
  else
    bad liveryJsonIsGenerated "$(diff "$work/livery.json" "$song/livery.json" | head -4 | tr '\n' ' ')"
  fi
else
  bad liveryJsonIsGenerated "nix eval --file palette.nix livery produced nothing"
fi

# ── the source IS the painted palette ────────────────────────────────────────
# livery.json is transience's generated record; modules/dendrites/stylix.nix
# reads the same palette.nix for the scheme it actually paints with. This
# proves the chain lands on a real host, not just that the two files agree on
# paper — and catches Aoide's own stylix facet quietly overriding it.
authored=$(jq -r '.base16 | to_entries | sort_by(.key) | .[] | "\(.key)=\(.value|ascii_downcase|ltrimstr("#"))"' "$song/livery.json")
# The --apply expression is Nix source and must reach nix verbatim.
# shellcheck disable=SC2016
painted=$(nix eval --json "$root#nixosConfigurations.yomi-strix.config.home-manager.users.khoa.lib.stylix.colors" \
  --apply 'c: builtins.listToAttrs (map (k: { name = k; value = c.${k}; }) (builtins.filter (n: builtins.match "base0[0-9A-F]" n != null) (builtins.attrNames c)))' 2>/dev/null \
  | jq -r 'to_entries | sort_by(.key) | .[] | "\(.key)=\(.value|ascii_downcase)"')
if [ -z "$painted" ]; then
  bad liveryMatchesStylixScheme "could not read lib.stylix.colors off yomi-strix"
elif [ "$authored" = "$painted" ]; then
  ok liveryMatchesStylixScheme "16 slots"
else
  bad liveryMatchesStylixScheme "$(diff <(printf '%s\n' "$authored") <(printf '%s\n' "$painted") | tr '\n' ' ')"
fi

# ── every placeholder is filled ──────────────────────────────────────────────
# A typo'd slot name does not throw: replaceStrings simply leaves `{{...}}` in
# the sheet and waybar renders the rule as invalid CSS, silently.
nix eval --raw "$root#nixosConfigurations.yomi-strix.config.home-manager.users.khoa.programs.waybar.style" \
  > "$work/rendered.css" 2>/dev/null
if [ ! -s "$work/rendered.css" ]; then
  bad styleRenders "waybar.style evaluated empty"
elif grep -q '{{' "$work/rendered.css"; then
  bad noUnfilledPlaceholders "$(grep -c '{{' "$work/rendered.css") placeholder(s) left in the rendered sheet"
else
  ok styleRenders "$(wc -l < "$work/rendered.css") lines"
  ok noUnfilledPlaceholders
fi

# The template is only worth having if it is actually parameterised.
n=$(grep -c '{{base16\.' "$song/source/waybar.css")
if [ "$n" -ge 1 ]; then
  ok templateIsParameterised "$n placeholder(s)"
else
  bad templateIsParameterised "source/waybar.css has no {{base16.*}} left — it is a static sheet"
fi
rule

# ── the two renderers agree ──────────────────────────────────────────────────
# The whole claim behind authoring in Aoide's schema: the same template file
# renders identically through pure Nix at build time and through lyra at
# runtime. If they ever disagree, the shared format is a fiction.
if ! command -v lyra >/dev/null 2>&1; then
  skip liveryLints      "lyra not on PATH"
  skip renderersAgree   "lyra not on PATH"
else
  if lyra livery lint "$song/livery.json" >"$work/lint" 2>&1 && grep -q '"ok":true' "$work/lint"; then
    ok liveryLints "v0 schema"
  else
    bad liveryLints "$(head -1 "$work/lint")"
  fi

  # lyra writes to stdout with no trailing newline; Nix's readFile keeps the
  # file's. Command substitution drops every trailing newline and printf puts
  # exactly one back, so both sides are compared as a stylesheet, not as
  # whitespace.
  norm() { printf '%s\n' "$(cat "$1")"; }
  lyra livery emit file "$song/livery.json" --template "$(cat "$song/source/waybar.css")" > "$work/lyra.css" 2>/dev/null
  if [ ! -s "$work/lyra.css" ]; then
    bad renderersAgree "lyra livery emit produced nothing"
  elif diff -q <(norm "$work/lyra.css") <(norm "$work/rendered.css") >/dev/null 2>&1; then
    ok renderersAgree "nix render == lyra livery emit file"
  else
    bad renderersAgree "$(diff <(norm "$work/lyra.css") <(norm "$work/rendered.css") | head -4 | tr '\n' ' ')"
  fi
fi
rule

# ── the split held ───────────────────────────────────────────────────────────
# The point of the rice is that look and wiring came apart. If the dendrite
# grows a stylesheet again, or the rice starts deciding whether waybar runs,
# the separation is back to being a comment.
if grep -qE '^\s*(style|settings) =' "$root/modules/dendrites/hyprland/waybar.nix"; then
  bad dendriteIsWiringOnly "modules/dendrites/hyprland/waybar.nix names style or settings again"
else
  ok dendriteIsWiringOnly
fi
if grep -qE '^\s*enable = true;' "$song/rice.nix"; then
  bad riceIsLookOnly "songbook/transience/rice.nix enables a program — that is the dendrite's job"
else
  ok riceIsLookOnly
fi

# The registry must name paths and import none, or an unselected rice would be
# evaluated on every host. tests/selection proves the mechanism; this proves
# this registry still uses it.
if grep -qE '^\s*(imports|import )' "$root/songbook/default.nix"; then
  bad registryImportsNothing "songbook/default.nix imports a rice body"
else
  ok registryImportsNothing "$(grep -c "= \./" "$root/songbook/default.nix") rice(s) named"
fi
rule

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
