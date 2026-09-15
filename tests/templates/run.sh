#!/usr/bin/env bash
# Proves templates/ is copyable: every template parses, and a tree assembled
# from them resolves against the REAL constructor — two hosts with different
# provider combinations, a user scope, and implementations that throw on import
# sitting where an unselected file would sit.
#
#   ./tests/templates/run.sh
set -uo pipefail
cd "$(dirname "$0")" || exit 1
root=$(cd ../.. && pwd)

rev=$(jq -r '.nodes.nixpkgs.locked.rev' "$root/flake.lock")
lib="(builtins.getFlake \"github:nixos/nixpkgs/$rev\").lib"

pass=0; fail=0
check() { # name  expected  actual
  if [ "$2" = "$3" ]; then printf '%-42s PASS\n' "$1"; pass=$((pass+1))
  else printf '%-42s FAIL (want %s, got %s)\n' "$1" "$2" "$3"; fail=$((fail+1)); fi
}

printf '%-42s %s\n' "CHECK" "RESULT"
printf '%s\n' "--------------------------------------------------------------"

# ── Every template parses ──────────────────────────────────────────────────
for f in "$root"/templates/example-*.nix; do
  if out=$(nix-instantiate --parse "$f" 2>&1 >/dev/null); then
    check "parses: $(basename "$f")" "" ""
  else
    printf '%-42s FAIL\n' "parses: $(basename "$f")"
    printf '%s\n' "$out" | sed 's/^/    | /'; fail=$((fail+1))
  fi
done

# ── A tree assembled from them ─────────────────────────────────────────────
t=$(mktemp -d) || exit 1
trap 'rm -rf "$t"' EXIT
T="$root/templates"

mkdir -p "$t"/modules/{aggregations/base,aggregations/workspace,aggregations/landmine,overrides,dendrites/notifications,dendrites/compositor/hyprland,nucleus} \
         "$t"/hosts/{examplehost,exampleserver} "$t"/users "$t"/pkgs/example-tool

cp "$T/example-default-registry.nix"          "$t/modules/default.nix"
cp "$T/example-default-aggregations.nix"      "$t/modules/aggregations/default.nix"
cp "$T/example-default-overrides.nix"         "$t/modules/overrides/default.nix"
cp "$T/example-override.nix"                 "$t/modules/overrides/examplefix.nix"
cp "$T/example-aggregation.nix"               "$t/modules/aggregations/workspace/default.nix"
cp "$T/example-default-provider-registry.nix" "$t/modules/dendrites/notifications/default.nix"
cp "$T/example-provider.nix"                  "$t/modules/dendrites/notifications/mako.nix"
cp "$T/example-nucleus-module.nix"            "$t/modules/nucleus/example.nix"
cp "$T/example-host.nix"                      "$t/hosts/examplehost/default.nix"
cp "$T/example-host-headless.nix"             "$t/hosts/exampleserver/default.nix"
cp "$T/example-user.nix"                      "$t/users/exampleuser.nix"
cp "$T/example-package.nix"                   "$t/pkgs/example-tool/default.nix"
for d in exampletool examplebar examplewidget; do
  cp "$T/example-dendrite.nix" "$t/modules/dendrites/$d.nix"
done

# Fixtures the templates deliberately do not ship: the second implementation of
# a capability, and the files that must stay unread.
cat > "$t/modules/dendrites/notifications/dunst.nix" <<'EOF'
{ homeManager = { ... }: { }; }
EOF
cat > "$t/modules/dendrites/compositor/default.nix" <<'EOF'
{ providers = { hyprland = ./hyprland/hyprland.nix; niri = ./niri.nix; landmine = ./landmine.nix; }; }
EOF
cat > "$t/modules/dendrites/compositor/hyprland/hyprland.nix" <<'EOF'
{ nixos = { ... }: { }; }
EOF
cat > "$t/modules/dendrites/compositor/niri.nix" <<'EOF'
{ nixos = { ... }: { }; }
EOF
cat > "$t/modules/dendrites/compositor/landmine.nix" <<'EOF'
throw "compositor/landmine.nix was imported — an unselected provider was evaluated"
EOF
cat > "$t/modules/aggregations/base/default.nix" <<'EOF'
# The smallest an aggregation body gets: a name, and what it selects. Both
# hosts take it, and it names a member workspace also names — two aggregations
# wanting one dendrite on the same terms merge into one selection.
{
  description = "What every host carries.";
  system.members = [ "exampletool" ];
}
EOF
cat > "$t/modules/aggregations/landmine/default.nix" <<'EOF'
throw "aggregations/landmine was imported — an unselected aggregation body was evaluated"
EOF

# A record nothing matches, sitting beside the one that does. `examplebar` is
# catalogued and wanted by the workspace group, but examplehost switches it off
# and exampleserver never takes the group — so no host selects it, and both
# bodies below must stay uncalled.
cat > "$t/modules/overrides/tripwire.nix" <<'EOF'
{
  dendrites = [ "examplebar" ];
  overlay = _final: _prev: throw "an unmatched override overlay was evaluated";
  nixos = _: throw "an unmatched override module was evaluated";
}
EOF

# Resolve both hosts and force everything a real host would force.
expr="
let
  lib = $lib;
  composition = import $root/lib/composition.nix { inherit lib; };
  registry = import $t/modules;
  hostNames = [ \"examplehost\" \"exampleserver\" ];
  resolve = name: host:
    let
      selection = composition.evalSelection { inherit registry; modules = [ host ]; };
      inv = composition.inventoryOf { hostName = name; inherit selection; };
      overrides = composition.overridesFor {
        inherit (selection) catalogue;
        inherit (registry) overrides;
        knownHosts = hostNames;
        hostName = name;
        inherit selection;
      };
      lanes = {
        system = composition.lanesFor {
          inherit (selection) catalogue;
          selected = selection.dendrites; lane = \"nixos\"; scope = \"for the system\";
        };
        home = lib.mapAttrs (n: u: composition.lanesFor {
          inherit (selection) catalogue;
          selected = u.dendrites; lane = \"homeManager\"; scope = \"by user '\\\${n}'\";
        }) selection.users;
      };
    in builtins.deepSeq [ lanes overrides ] { inherit inv lanes overrides; };
  a = resolve \"examplehost\" $t/hosts/examplehost;
  b = resolve \"exampleserver\" $t/hosts/exampleserver;
in {
  aCompositor = a.inv.dendrites.compositor.provider;
  aNotifications = a.inv.users.exampleuser.dendrites.notifications.provider;
  aOptOut = a.inv.dendrites ? examplebar;
  aGroupMember = a.inv.dendrites ? exampletool;
  aUserHomeLanes = builtins.length a.lanes.home.exampleuser;
  aUserAggregation = a.inv.users.exampleuser.aggregation;
  bCompositor = b.inv.dendrites.compositor.provider;
  bNotifications = b.inv.dendrites ? notifications;
  bHomeManager = b.inv.users.exampleuser.homeManager;
  bHomeLanes = builtins.length b.lanes.home.exampleuser;

  # The override record: matched where its host filter and a selected target
  # agree, and carrying all three halves.
  aMatched = builtins.concatStringsSep \",\" a.overrides.matched;
  aHomeFix = builtins.length a.overrides.homeManager.exampleuser;
  bMatched = builtins.length b.overrides.matched;

  # The overlay really is an overlay: feed it a stub package set shaped like
  # the one attribute it touches and watch it come back overridden.
  aOverlayApplies =
    ((builtins.head a.overrides.overlays) { } {
      ripgrep.overrideAttrs = f: { inherit (f { }) doCheck; };
    }).ripgrep.doCheck;

  # And the nixos half names REAL options: evaluated by the real NixOS module
  # system, so a misspelt option is a failing test rather than a comment.
  recordUsesRealOptions = (lib.nixosSystem {
    modules = [
      (builtins.head a.overrides.nixos)
      { nixpkgs.hostPlatform = \"x86_64-linux\";
        boot.loader.grub.enable = false;
        fileSystems.\"/\" = { device = \"none\"; fsType = \"tmpfs\"; };
        system.stateVersion = \"25.11\";
      }
    ];
  }).config.systemd.services.example.serviceConfig.DynamicUser;
}"

if ! out=$(nix eval --impure --json --show-trace --expr "$expr" 2>&1); then
  printf '%-42s FAIL\n' "templates resolve"
  printf '%s\n' "$out" | grep -v '^ *$' | tail -12 | sed 's/^/    | /'
  fail=$((fail+1))
else
  g() { printf '%s' "$out" | jq -r ".$1"; }
  # The host chose under the aggregation that owns the capability — no
  # top-level dendrites override anywhere in example-host.nix.
  check "host picks provider under aggregation"   "hyprland" "$(g aCompositor)"
  check "user overrides the group's shared default" "dunst" "$(g aNotifications)"
  check "enable = false beats group membership"   "false"    "$(g aOptOut)"
  check "group membership reaches the host"       "true"     "$(g aGroupMember)"
  check "user scope gets its own home lanes"      "3"        "$(g aUserHomeLanes)"
  check "user selects the group's home half"      "workspace" "$(g 'aUserAggregation[0]')"
  # Second host, same vocabulary, different answers. niri and the landmine
  # aggregation sit right beside what these two selected and stay unread — the
  # resolution above would have thrown on import otherwise.
  check "second host picks the other provider"    "niri"     "$(g bCompositor)"
  check "unselected group's members stay unselected" "false" "$(g bNotifications)"
  check "no home lane where HM is off"            "false"    "$(g bHomeManager)"
  check "and no home modules are assembled"       "0"        "$(g bHomeLanes)"
  # The override record. tripwire.nix targets a capability neither host
  # selected and throws in both its bodies; the deepSeq above would have caught
  # a call, so "unmatched work is never done" is proved, not asserted.
  check "record matches its targeted host"        "examplefix" "$(g aMatched)"
  check "its overlay applies to the host packages" "false"   "$(g aOverlayApplies)"
  check "its home half rides the selecting user"  "1"        "$(g aHomeFix)"
  check "its nixos half names real NixOS options" "false"    "$(g recordUsesRealOptions)"
  check "host filter keeps it off the other host" "0"        "$(g bMatched)"
fi

printf '%s\n' "--------------------------------------------------------------"
printf '%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
