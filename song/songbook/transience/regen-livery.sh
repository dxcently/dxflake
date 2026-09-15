#!/usr/bin/env bash
# regen-livery.sh — writes livery.json from palette.nix, the one source of the
# transience palette. livery.json is generated, not authored: lyra and humans
# still read it as a real path, so it stays checked in, but edit palette.nix
# and rerun this rather than editing the JSON.
#
#   ./song/songbook/transience/regen-livery.sh
set -euo pipefail
cd "$(dirname "$0")" || exit 1

# The temp lands beside the target, not in /tmp: same filesystem, so the mv is
# atomic, and it inherits the umask instead of mktemp's 0600.
out=livery.json.new
trap 'rm -f "$out"' EXIT
nix eval --json --file palette.nix livery | jq . > "$out"
mv "$out" livery.json
