#!/usr/bin/env bash
# The rice is a look with one source, palette.nix, read by three places: the
# generated theme.json, the Stylix scheme that actually paints GTK and Qt, and
# a stylesheet template that two different renderers can fill. Each place can
# drift from the source, and drift in a look is silent — nothing fails to
# evaluate, the desktop just comes up slightly wrong. So each one gets an
# assertion.
#
#   ./tests/rice/run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit 1
root=$(cd ../.. && pwd)
look=$root/modules/aggregations/shell/transience

pass=0; fail=0
ok()   { printf '%-34s PASS%s\n' "$1" "${2:+  ($2)}"; pass=$((pass+1)); }
bad()  { printf '%-34s FAIL  %s\n' "$1" "$2"; fail=$((fail+1)); }
skip() { printf '%-34s KNOWN %s\n' "$1" "$2"; }
rule() { printf '%s\n' "------------------------------------------------------------"; }

work=$(mktemp -d); trap 'rm -rf "$work"' EXIT

# Never the live root: strx reads STRILLIX_ROOT for its stage, and nothing here
# is allowed near it. Every strx call below is also given an explicit file path,
# so the staged rice is not even consulted.
export STRILLIX_ROOT=$work/strillix-root
export AOIDE_ROOT=$work/aoide-root
mkdir -p "$STRILLIX_ROOT"

# ── the record matches the source ────────────────────────────────────────────
# theme.json is generated from palette.nix, not authored — if a hex is ever
# hand-edited in the JSON without touching palette.nix, this is what catches
# the checked-in file going stale.
if command -v nix >/dev/null 2>&1 &&
  nix eval --json --file "$look/palette.nix" theme 2>/dev/null | jq . >"$work/theme.json" 2>/dev/null &&
  [ -s "$work/theme.json" ]; then
  if diff -q "$work/theme.json" "$look/theme.json" >/dev/null 2>&1; then
    ok themeJsonIsGenerated "matches palette.nix"
  else
    bad themeJsonIsGenerated "$(diff "$work/theme.json" "$look/theme.json" | head -4 | tr '\n' ' ')"
  fi
else
  bad themeJsonIsGenerated "nix eval --file palette.nix theme produced nothing"
fi

# ── the source IS the painted palette ────────────────────────────────────────
# theme.json is transience's generated record; modules/dendrites/stylix.nix
# reads the same palette.nix for the scheme it actually paints with. This
# proves the chain lands on a real host, not just that the two files agree on
# paper — and catches Aoide's own stylix lane quietly overriding it.
authored=$(jq -r '.base16 | to_entries | sort_by(.key) | .[] | "\(.key)=\(.value|ascii_downcase|ltrimstr("#"))"' "$look/theme.json")
# The --apply expression is Nix source and must reach nix verbatim.
# shellcheck disable=SC2016
painted=$(nix eval --json "$root#nixosConfigurations.yomi-strix.config.home-manager.users.khoa.lib.stylix.colors" \
  --apply 'c: builtins.listToAttrs (map (k: { name = k; value = c.${k}; }) (builtins.filter (n: builtins.match "base0[0-9A-F]" n != null) (builtins.attrNames c)))' 2>/dev/null \
  | jq -r 'to_entries | sort_by(.key) | .[] | "\(.key)=\(.value|ascii_downcase)"')
if [ -z "$painted" ]; then
  bad themeMatchesStylixScheme "could not read lib.stylix.colors off yomi-strix"
elif [ "$authored" = "$painted" ]; then
  ok themeMatchesStylixScheme "16 slots"
else
  bad themeMatchesStylixScheme "$(diff <(printf '%s\n' "$authored") <(printf '%s\n' "$painted") | tr '\n' ' ')"
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
n=$(grep -c '{{base16\.' "$look/source/waybar.css")
if [ "$n" -ge 1 ]; then
  ok templateIsParameterised "$n placeholder(s)"
else
  bad templateIsParameterised "source/waybar.css has no {{base16.*}} left — it is a static sheet"
fi
rule

# ── the two renderers agree ──────────────────────────────────────────────────
# The whole claim behind authoring in Aoide's schema: the same template file
# renders identically through pure Nix at build time and through strx at
# runtime. If they ever disagree, the shared format is a fiction.
if ! command -v strx >/dev/null 2>&1; then
  skip themeLints      "strx not on PATH"
  skip renderersAgree   "strx not on PATH"
else
  if strx theme lint "$look/theme.json" >"$work/lint" 2>&1 && grep -q '"ok":true' "$work/lint"; then
    ok themeLints "v0 schema"
  else
    bad themeLints "$(head -1 "$work/lint")"
  fi

  # strx writes to stdout with no trailing newline; Nix's readFile keeps the
  # file's. Command substitution drops every trailing newline and printf puts
  # exactly one back, so both sides are compared as a stylesheet, not as
  # whitespace.
  norm() { printf '%s\n' "$(cat "$1")"; }
  strx theme emit file "$look/theme.json" --template "$(cat "$look/source/waybar.css")" > "$work/strx.css" 2>/dev/null
  if [ ! -s "$work/strx.css" ]; then
    bad renderersAgree "strx theme emit produced nothing"
  elif diff -q <(norm "$work/strx.css") <(norm "$work/rendered.css") >/dev/null 2>&1; then
    ok renderersAgree "nix render == strx theme emit file"
  else
    bad renderersAgree "$(diff <(norm "$work/strx.css") <(norm "$work/rendered.css") | head -4 | tr '\n' ' ')"
  fi
fi
rule

# ── the split held ───────────────────────────────────────────────────────────
# The point of the rice is that look and wiring came apart. If the dendrite
# grows a stylesheet again, or the rice starts deciding whether waybar runs,
# the separation is back to being a comment.
if grep -qE '^\s*(style|settings) =' "$root/modules/dendrites/waybar.nix"; then
  bad dendriteIsWiringOnly "modules/dendrites/waybar.nix names style or settings again"
else
  ok dendriteIsWiringOnly
fi
if grep -qE '^\s*enable = true;' "$look/look.nix"; then
  bad riceIsLookOnly "modules/aggregations/shell/transience/look.nix enables a program — that is the dendrite's job"
else
  ok riceIsLookOnly
fi

rule

printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
