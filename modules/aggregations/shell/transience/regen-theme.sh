#!/usr/bin/env bash
# regen-theme.sh — writes theme.json from palette.nix, the one source of the
# transience palette. theme.json is generated, not authored: strx and humans
# still read it as a real path, so it stays checked in, but edit palette.nix
# and rerun this rather than editing the JSON.
#
#   ./modules/aggregations/shell/transience/regen-theme.sh
set -euo pipefail
cd "$(dirname "$0")" || exit 1

# The temp lands beside the target, not in /tmp: same filesystem, so the mv is
# atomic, and it inherits the umask instead of mktemp's 0600.
out=theme.json.new
trap 'rm -f "$out"' EXIT
nix eval --json --file palette.nix theme | jq . > "$out"
mv "$out" theme.json
