# AGENTS.md — dxflake

A multi-host NixOS flake (`chiyo` laptop · `osaka` workstation · `sakaki` server ·
`yomi-strix` desktop).
This file is a **registry**: where things live and how to add them. For the *why*,
read `README.md` and `~/Aoide/docs/architecture/NIX-COMPOSITION.md`, which is the
authoritative design this tree implements.

## How it operates

Selection is resolved **before** any platform module graph exists.

`mkDefault` sets definition priority and cannot decide imports; `mkIf` cannot keep
an imported module's declarations out of the graph that imported them. So
`lib/composition.nix` runs two passes:

```text
modules/default.nix (catalogue)  +  modules/aggregations.nix  +  hosts/<host>
                              |
                 pass 1: ordinary lib.evalModules
                              |
          enabled names + chosen providers + users and their lanes
                              |
                 pass 2: import ONLY what was selected
                              |
        nucleus + account lanes + system lanes + per-user home lanes
                              |
                     nixpkgs.lib.nixosSystem
```

Nothing walks the filesystem. A capability exists because `modules/default.nix`
names its path; a name with no catalogue line is unreachable, which is what
shelving means now (the `_` filename prefix is the older convention and still
marks parked files).

- **Catalogue** — `modules/default.nix`, one `name = ./path;` line per capability.
  It generates `dendrites.<name>.enable` and `.provider`, so an unknown name
  fails as an option that does not exist, naming the file that asked for it.
- **Dendrite** — a selectable capability. One file exposing the lanes it
  supports (`{ nixos = …; }`, `{ homeManager = …; }`, or both), or a directory
  whose `default.nix` lists `providers = { … }` and imports none of them.
- **Provider** — one implementation of a multi-implementation capability, and
  exclusive within a scope. `gpu` is the worked example: `amd` and `intel`, and
  the unchosen file is never imported.
- **Aggregation** — `modules/aggregations.nix`. Shared membership plus the
  preferences that belong with it, using `mkDefault` so a host's ordinary
  selection outranks it. Two aggregations that default the same option to
  different values collide; import order never picks a winner.
- **Nucleus** — `modules/nucleus/`, imported unconditionally on every host.
- **Lane** — a module for one evaluator: `nixos`, `homeManager` (`darwin` is in
  the vocabulary, unused here). Selecting a dendrite for the system imports its
  `nixos` lane; selecting it under a user imports its `homeManager` lane.
  Neither installs the other, and selecting a lane a dendrite does not expose is
  an error naming the dendrite, the scope and the lanes it does support.

## Adding things

- **A dendrite** — write the file exposing its lane(s), add one catalogue line,
  and select it from a host or an aggregation. Nothing else.
- **A provider** — add the file and one line to that dendrite's `providers`
  registry; select it where wanted.
- **A shared preference or package fix** — the owning aggregation, once. Never
  repeated across hosts.
- **A host exception** — that host's own selection (`enable = false` beats a
  `mkDefault true`), or an ordinary setting in its `nixos` module.
- **A user** — one definition under `users/`, attached by the hosts that want
  it. `users/khoa.nix` carries the account in its `nixos` lane and the shared
  home floor in its `homeManager` lane; there are no per-host copies.

A host file is selection first, then its own platform settings under `nixos`.
That `nixos` block is an ordinary NixOS module: hardware imports, `dx.*` knobs,
host-only overlays and packages.

**Never** name a module file from anywhere but the catalogue.

## Reviewing what a host resolved

```sh
nix eval --json .#inventory.osaka | jq        # dendrites, providers, users, sources
```

Generated from selection, never maintained by hand.

## Verify

```sh
nixfmt <file>.nix                          # format (repo style)
./tests/selection/run.sh                   # the constructor's executable schema
nix eval .#nixosConfigurations.<name>.config.system.build.toplevel.drvPath
sudo nixos-rebuild switch --flake .#<name> # apply to a host (User only)
```

`tests/selection/` is the schema, not a description of one: its fixtures throw
on import, so "an unselected file is never evaluated" is proved rather than
asserted, and the runner greps real stderr, so a vague diagnostic fails.

## The Aoide seam

`flake.nix` still reaches into the Aoide input's tree — `modules/default.nix`,
`lib/livery.nix`, `lib/pkgs.nix` and the five `song/songbook/*/rice.nix` files —
because the Aoide flake exports `packages`, `songbookManifest` and
`aoideOptions` but no `nixosModules` and no `lib`. Those paths are named in one
place in `flake.nix` and collapse to public imports once upstream exports
`nixosModules.default`, a songbook module, `lib.livery.resolve` and
`overlays.default`. Do not add new private-tree paths elsewhere.

Melete (`modules/dendrites/melete.nix`) is sakaki-only, pinned client v0.2.0 via
`pkgs/melete-client-package.nix`. Its spawned agent turns use the real `claude`
CLI by default (`[claude] binary = "claude"` in the out-of-band `config.toml`);
the pi-agent shim at `~/.config/melete/bin/melete-agent` is retained on disk but
not routed to.

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
- `~/Magi/06 • MAGI-WIKI/03 Homelab/notes/Build-Runbook.md` — sops setup, adding a host.
