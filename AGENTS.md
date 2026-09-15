# AGENTS.md — dxflake

A multi-host NixOS flake (`chiyo` laptop · `osaka` workstation · `sakaki` server ·
`yomi-strix` desktop).
This file is a **registry**: where things live and how to add them. For the *why*,
read `README.md` and `~/Aoide/docs/architecture/NIX-COMPOSITION.md`, which is the
authoritative design this tree implements. To add a file, start from
`templates/` — one copyable example per authoring role, with `templates/README.md`
mapping role to destination.

## How it operates

Selection is resolved **before** any platform module graph exists.

`mkDefault` sets definition priority and cannot decide imports; `mkIf` cannot keep
an imported module's declarations out of the graph that imported them. So
`lib/composition.nix` resolves the whole selection first, with an ordinary
`lib.evalModules` pass that knows nothing about NixOS, and only then assembles
the import list:

```text
modules/default.nix (catalogue)  modules/aggregations/ (discovery)  hosts/<host>
                              |
      gate     which aggregations did this host or its users select?
                              |
      select   import THOSE bodies; they declare their provider selectors
               and write their membership. No other body is read.
                              |
      enabled names + chosen providers + per-user home selections
                              |
      match    which override records name something this host selected?
                              |
      platform import ONLY the dendrite and provider files selection kept
                              |
        nucleus + account lanes + system lanes + per-user home lanes
            + the overlays and modules the matched records carried
                              |
                     nixpkgs.lib.nixosSystem
```

The gate step exists because the host interface nests provider choices under the
aggregation that owns them, and those option names come from the aggregation's
own body. In the gate step every discovered aggregation declares only `enable`
and the rest of its attrset is freeform and ignored; in the select step the
chosen bodies declare the real thing. A body is **data**, so it cannot enable
another aggregation — the gate step's answer is final, and no recursion
machinery exists.

**The evaluation boundary, exactly.** `modules/aggregations/default.nix` names
directories without importing them. An aggregation body is imported iff this
host *or one of its users* selected it — the union, so a body a user selected is
also present, gated off, in the host scope. A dendrite implementation and a
provider file are imported only in the platform pass, only if selection kept
them. Nothing else under `modules/dendrites/` is read at all.

**Override records are the one weaker boundary, and it is stated rather than
glossed.** `modules/overrides/*.nix` is imported on every host, because matching
means reading which dendrites a record targets. What an unmatched host never
spends is the *work*: `overlay`, `nixos` and `homeManager` are functions and
nothing calls them. Keep imports, fetches and package computation inside those
functions — metadata that computes defeats this, and only the function bodies
are proved cold.

- **Catalogue** — `modules/default.nix`. Not a module: plain data, one
  `name = ./path;` line per capability plus `aggregations = import ./aggregations;`.
  It generates `dendrites.<name>.enable` and `.provider`, so an unknown name
  fails as an option that does not exist, naming the file that asked for it. A
  name with no catalogue line is unreachable, which is what shelving means now
  (the `_` filename prefix is the older convention and still marks parked files).
- **Dendrite** — a selectable capability. One file exposing the lanes it
  supports (`{ nixos = …; }`, `{ homeManager = …; }`, or both), or a directory
  whose `default.nix` lists `providers = { … }` and imports none of them.
- **Provider** — one implementation of a multi-implementation capability, and
  exclusive within a scope. `compositor` and `gpu` are the worked examples; the
  unchosen file is never imported. A single-implementation dendrite has no
  provider option at all. A registry may give each provider a folder of its own —
  `compositor/hyprland/hyprland.nix` — holding that provider's entry file plus
  every dendrite written or compiled against that implementation, so the folder
  is as unreachable as the file was.
- **Aggregation** — one group, one directory: `modules/aggregations/<group>/default.nix`.
  Its `default.nix` is plain data — no options, no `mkIf`, no arguments:

  ```nix
  {
    description = "One line, shown on the generated enable option.";
    system = {
      members = [ "catalogue-name" … ];   # single-implementation members
      providers.compositor = null;        # provider-bearing member, no default
      nixos = { … };                      # optional preference that rides along
    };
    home = {
      members = [ … ];
      providers.notifications = "mako";   # shared default a user may override
      homeManager = { … };                # optional
    };
  }
  ```

  `modules/aggregations/default.nix` discovers every immediate child directory
  holding a `default.nix` and does nothing else — there is no collector line to
  add. `aggregation.desktop.enable` on the host selects the `system` half;
  `users.khoa.aggregation.desktop.enable` selects the `home` half. An absent half
  is a real answer, not a placeholder.

  Each key of a `providers` attrset becomes a selector on that aggregation's own
  interface, in that scope — which is where a host states its choice:

  ```nix
  aggregation.shell = {
    enable = true;
    compositor.provider = "hyprland";
  };
  ```

  Membership and provider are `mkDefault`, so an ordinary selection outranks
  them, two aggregations naming the same dendrite on the same terms **merge**
  into one selection, and two that name different providers for it collide with
  both values in the error. Import order never picks a winner.

  What a group **installs** is not membership. A package list answers no
  question a host could answer differently, so it gets no catalogue line and is
  not a dendrite: it goes in the group's own `nixos`/`homeManager` half, in a
  `packages.nix` beside the `default.nix` when it is long enough to want a file
  (`desktop/`, `shell/`) and inline when it is not (`gaming`). Those lists are
  `lib.mkAfter`, so they order last into `system.path`, where collisions resolve
  first-wins — a group's convenience list never shadows a selected capability.

  Membership is **static**: the list does not vary with the provider that was
  chosen. So a member only one implementation can run — a compositor plugin, a
  config written in that compositor's own language — belongs to an aggregation
  of its own, beside the provider-bearing one. `shell` holds what any wlroots
  compositor can run and owns `compositor.provider`; `compositor` holds what
  only Hyprland can, and a host on another compositor selects `shell` alone.
- **Override record** — a fix that belongs to a capability rather than to a
  host: `modules/overrides/<name>.nix`. It names the dendrites it is about,
  optionally the hosts it is confined to, and carries an `overlay`, a `nixos`
  module, a `homeManager` module, or any combination:

  ```nix
  {
    dendrites = [ "browser" ];        # catalogue names — required
    hosts = [ "osaka" "sakaki" ];     # optional; omit for every host that selected one
    overlay = _final: prev: { … };    # host package set
    nixos = { lib, ... }: { … };      # deferred platform module
    homeManager = { … };              # rides only the users who selected a target
  }
  ```

  Discovery is every `*.nix` file beside `modules/overrides/default.nix`; there
  is no catalogue line. A record **never selects anything** — targeting a
  capability nobody chose is a record that does not apply. A record applies at
  most once however many of its targets were selected, matched records apply in
  record-name order, and a record outranks everything the constructor imported
  on its behalf while the host's own `nixos` block still outranks the record.
  Unknown fields, unknown targets and unknown host names fail on *every* host,
  naming the record — a broken record cannot hide on the machines it would not
  have applied to.
- **Nucleus** — `modules/nucleus/`, imported unconditionally on every host.
- **Lane** — a module for one evaluator: `nixos`, `homeManager` (`darwin` is in
  the vocabulary, unused here). Selecting a dendrite for the system imports its
  `nixos` lane; selecting it under a user imports its `homeManager` lane.
  Neither installs the other, and selecting a lane a dendrite does not expose is
  an error naming the dendrite, the scope and the lanes it does support.

## Adding things

Every row below has a template in `templates/`; `templates/README.md` maps role
to destination.

- **A dendrite** — write the file exposing its lane(s), add one catalogue line,
  and select it from a host or a group. Nothing else.
- **A provider** — add the file and one line to that dendrite's `providers`
  registry; select it where wanted.
- **A group** — a directory under `modules/aggregations/` whose `default.nix`
  holds the data above. Discovery finds it; there is no import line anywhere.
- **A backend-specific member** — one an aggregation cannot name because only
  one provider can run it. Its own group beside the provider-bearing one
  (`modules/aggregations/compositor/` beside `shell/`), so choosing another
  provider leaves it unselected and unevaluated.
- **A package the group just installs** — that group's `packages.nix`, or its
  inline `nixos` half. Never a catalogue line: there is nothing to select.
- **A rice** — structurally a provider, so `example-provider.nix` is still the
  template, but it lives at `song/songbook/<name>/rice.nix` beside its `livery.json`,
  `design/intent.md` and source assets, and `song/songbook/default.nix` is its
  registry. The look only; the wiring stays in the dendrites.
  `song/songbook/transience/` is the worked example.
- **A shared preference or package fix** — the owning group's `default.nix`,
  once, in the half that matches the lane it rides: `system.nixos` for a
  deferred platform preference, `home.homeManager` for a home one. Never
  repeated across hosts.
- **A capability-wide fix** — an override record under `modules/overrides/`,
  when a package or a setting is wrong for everyone who runs the thing.
  Repeating it per host drifts; putting it in the dendrite confuses what the
  thing IS with a patch log; a new aggregation or provider turns a patch into a
  capability. None of those.
- **A host exception** — that host's own selection (`enable = false` beats a
  `mkDefault true`, and `dendrites.<name>.provider` beats a group's choice), or
  an ordinary setting in its `nixos` module.
- **A user** — one definition under `users/`, attached by the hosts that want
  it. `users/khoa.nix` carries the account in its `nixos` lane and the shared
  home floor in its `homeManager` lane; there are no per-host copies.

A host file is selection first, then its own platform settings under `nixos`.
That `nixos` block is an ordinary NixOS module: hardware imports, `dx.*` knobs,
host-only overlays and packages.

**Never** name a module file from anywhere but the catalogue.

## Reviewing what a host resolved

```sh
nix eval --json .#inventory.osaka | jq        # aggregations, dendrites, providers, users, sources, matched overrides
```

Generated from selection, never maintained by hand.

## Verify

```sh
nixfmt <file>.nix                          # format (repo style)
./tests/selection/run.sh                   # the constructor's executable schema
./tests/templates/run.sh                   # templates/ still copyable and correct
./tests/session-guard/run.sh               # nested Hyprland cannot take the desktop
./tests/rice/run.sh                        # the rice and the palette have not drifted
nix eval .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath
sudo nixos-rebuild switch --flake .#<name> # apply to a host (User only)
```

`tests/selection/` is the schema, not a description of one: its fixtures throw
on import, so "an unselected file is never evaluated" is proved rather than
asserted — for an unselected provider, for an unselected aggregation body, and
for an unmatched override record whose overlay and module both throw — and the
runner greps real stderr, so a vague diagnostic fails.
`tests/templates/` assembles a whole tree out of `templates/`, resolves two
hosts against the real constructor, and checks the same non-evaluation there. It
also runs the override template's `nixos` half through the real NixOS module
system, so "real options" is checked rather than claimed.

`tests/rice/` covers the look: that transience's authored `livery.json` still
agrees with the Stylix scheme that actually paints, that every `{{base16.*}}`
placeholder in the stylesheet is filled, that the pure-Nix render and
`lyra livery emit file` produce the same bytes, and that look and wiring have
not leaked back into each other. Drift in a look is silent — nothing fails to
evaluate, the desktop just comes up slightly wrong — so each pair that can
drift gets an assertion.

`tests/session-guard/` covers the session handoff (below). Its behavioural half
runs the shipped guard script against a stubbed `hyprctl`/`systemctl`/`dbus`,
over instance lists derived from a real `hyprctl instances -j` captured during
a live nesting; its source half renders every host's `hyprland.conf` out of the
flake and fails if home-manager's unguarded lines are back. A host the fix
cannot reach is named in the runner with its reason and reports `KNOWN` — and
fails if it ever comes back clean, so the exemption cannot outlive the bug.

## The rice

The look is a capability with providers, like the compositor:
`song/songbook/` is the registry, one directory per rice, and the `shell`
aggregation answers it — `transience` by default, because dxflake ships one
rice and that is the look this desktop has always had.
`users.<u>.aggregation.shell.rice.provider` is where a host says otherwise.

A **rice** is the palette and the stylesheets. A **dendrite** is whether the
program runs. `modules/dendrites/waybar.nix` is `enable` and a systemd
decision; `song/songbook/transience/rice.nix` is the sheet and the bar's own
composition. Swapping the rice must never mean re-deciding whether the bar
exists, and `tests/rice` fails if either side grows back into the other.

`song/songbook/transience/livery.json` is authored in **Aoide's v0 livery schema**,
which is the whole bridge and is deliberately the only one: `lyra livery lint`
is a real check on it, and `source/waybar.css` uses Lyra's own `{{group.key}}`
template syntax, so the identical file renders through pure Nix at build time
and through `lyra livery emit file` at runtime — `tests/rice` asserts the two
agree byte for byte. Nothing here is declared into Aoide, nothing stages or
hot-loads, and `lyra rice compose/stage/draft/declare` do not apply: those are
the QML self-ricing loop, and no arrangement entry can carry a GTK stylesheet.
`song/songbook/transience/design/intent.md` records the boundary in full.

## The Hyprland split

`modules/dendrites/compositor/hyprland/hyprland.nix` is the provider and does one
job: make a Hyprland session RUN. Package, Wayland environment, monitors, and
the guarded session handoff below. It installs nothing.

Everything opinionated is a dendrite selected by name.
`modules/dendrites/compositor/hyprland/` holds only what is written or compiled
against Hyprland itself — `hyprland-keybinds`, `hyprland-decoration`,
`hyprland-autostart`, `hyprglass` — and the `compositor` aggregation names
exactly those four. The surfaces `waybar`/`rofi`/`satty`/`wlogout` are
compositor-agnostic, so they sit at the dendrite root like every other
single-file capability and belong to `shell`, which also installs the Wayland
tool belt from its own `packages.nix`. That folder is the hyprland provider's:
one folder per provider under the `compositor` registry, holding the provider
entry and everything written against that compositor. Nothing walks it; each
file is reachable only through its own catalogue line. (`compositor/` and
`gpu/` carry a `default.nix` — those are provider registries, the thing the
folders sit inside.)

`docs/HYPRLAND-SPLIT.md` maps every old block to the file that owns it now, and
records which units are independently selectable versus private helpers.

One ordering consequence: `exec-once` is now written from two files, and list
definitions concatenate in module order. The provider pins its guard entry with
`lib.mkBefore` so it stays first; `tests/session-guard` asserts that against the
rendered config.

## The session handoff

`wayland.windowManager.hyprland.systemd.enable` is **off** in
`modules/dendrites/compositor/hyprland/hyprland.nix`, and the two lines it used
to write are issued by
`modules/dendrites/compositor/hyprland/hypr-session-import.sh` instead,
from `exec-once` and `exec-shutdown`. This is a guard, not a removal: the
environment import, the target restart and the stop on exit all still happen,
and `hyprland-session.target` is re-declared in the dendrite with home-manager's
own `Unit` block, verbatim.

The reason is that home-manager's lines are unconditional, and a nested
Hyprland — one launched from a terminal inside a running session — loads the
same config:

```
  login Hyprland  ── wayland-1 ── owns hyprland-session.target
        └── terminal
              └── nested Hyprland ── wayland-2
                    exec-once:     repoints the user manager at wayland-2,
                                   stops + restarts the target, and every
                                   service on it follows into the window
                    exec-shutdown: closing the window stops the REAL target
```

The guard asks Hyprland's own IPC — `hyprctl instances` — whether a live
instance started *before* this one. If one did, this instance is not the
session owner and does nothing. Every uncertain answer ("no IPC", "I am not in
the list", "that entry has no timestamp") resolves to *owner*, because a guard
that cannot tell must never be the thing that breaks a login. The script's
header records the two cheaper discriminators that were tried against the live
fleet and rejected.

It cannot be expressed as a home-manager option: the generated line is
`dbus-update-activation-environment … && systemctl …`, and `systemd.variables`
and `systemd.extraCommands` splice into the middle of it, so neither can put a
condition ahead of the part that does the damage. `--all` stays, because
narrowing the variable set here would change what a normal login exports.

**chiyo is not covered.** Its `hyprland.conf` comes from Aoide's compositor
facet, which carries the same defect and belongs to Fable; the durable fix is
upstream (in home-manager, ultimately) and reaches dxflake by pin bump. Patching
it from here would put a second writer on the very leaf options
`modules/dendrites/aoide.nix` documents as a silent-merge trap.
`tests/session-guard/run.sh` reports it `KNOWN` and will fail the moment the
exemption stops being true.

## The Aoide seam

`flake.nix` still reaches into the Aoide input's tree — `modules/default.nix`,
`lib/livery.nix`, `lib/pkgs.nix` and the five `song/songbook/*/rice.nix` files —
because the Aoide flake exports `packages`, `songbookManifest` and
`aoideOptions` but no `nixosModules` and no `lib`. Those paths are named in one
place in `flake.nix` and collapse to public imports once upstream exports
`nixosModules.default`, a songbook module, `lib.livery.resolve` and
`overlays.default`. Do not add new private-tree paths elsewhere.

Melete and Mneme (`modules/dendrites/{melete,mneme}.nix`) are sakaki-only. Both
build from their canonical **private** GitHub repos — `noah427/melete`,
`noah427/mneme` — pinned to `refs/heads/master` by `flake.lock`. A checkout in
`~/melete` is a place to develop, never the pin: bump with
`nix flake update melete-src` (or `mneme-src`), and use
`--override-input melete-src path:/home/khoa/melete` for a one-off dirty build.
Because the repos and their cargo git dependencies are private, **evaluate as
`khoa`** (`nh os switch`, which is what `dxrebuild` runs) — a bare
`sudo nixos-rebuild` evaluates as root, which has no GitHub credential.

Melete's spawned agent turns use the real `claude` CLI by default
(`[claude] binary = "claude"` in the out-of-band `config.toml`); the pi-agent
shim at `~/.config/melete/bin/melete-agent` is retained on disk but not routed
to.

## Secrets (sops-nix)

`modules/nucleus/sops.nix` wires it: each host decrypts with its **own SSH host
key** (`ssh-to-age`), so no private key is ever copied around. To use a secret:

1. Ensure the host's `ssh-to-age` pubkey is a recipient in `.sops.yaml` (already
   covers all hosts). After changing recipients, re-encrypt:
   `sops updatekeys secrets/<name>.yaml`.
2. Store the encrypted payload in `secrets/<name>.yaml` (`sops secrets/<name>.yaml`).
3. Consume it: `sops.secrets."<name>".sopsFile = ../../secrets/<name>.yaml;`, then
   read `config.sops.secrets."<name>".path`. For string interpolation, render a
   `sops.templates` entry with `config.sops.placeholder."<name>"`.

## Deeper reference

- `~/Aoide/docs/architecture/NIX-COMPOSITION.md` — the authoritative design.
- `README.md` — architecture overview.
- `templates/README.md` — one copyable example per authoring role.
- `~/Magi/06 • MAGI-WIKI/03 Homelab/notes/Build-Runbook.md` — sops setup, adding a host.
