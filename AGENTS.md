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
      platform import ONLY the dendrite and provider files selection kept
                              |
        nucleus + account lanes + system lanes + per-user home lanes
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
  provider option at all.
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
- **A shared preference or package fix** — the owning group's `default.nix`,
  once, in the half that matches the lane it rides: `system.nixos` for a
  deferred platform preference, `home.homeManager` for a home one. Never
  repeated across hosts.
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
nix eval --json .#inventory.osaka | jq        # aggregations, dendrites, providers, users, sources
```

Generated from selection, never maintained by hand.

## Verify

```sh
nixfmt <file>.nix                          # format (repo style)
./tests/selection/run.sh                   # the constructor's executable schema
./tests/templates/run.sh                   # templates/ still copyable and correct
nix eval .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath
sudo nixos-rebuild switch --flake .#<name> # apply to a host (User only)
```

`tests/selection/` is the schema, not a description of one: its fixtures throw
on import, so "an unselected file is never evaluated" is proved rather than
asserted — for an unselected provider *and* for an unselected aggregation body —
and the runner greps real stderr, so a vague diagnostic fails.
`tests/templates/` assembles a whole tree out of `templates/`, resolves two
hosts against the real constructor, and checks the same non-evaluation there.

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
