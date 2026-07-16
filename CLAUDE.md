# CLAUDE.md — dxflake

A multi-host NixOS flake (`chiyo` laptop · `osaka` workstation · `sakaki` server).
This file is a **registry**: where things live and how to add them. For the *why*,
read `README.md` (*Architecture overview*, *Adding a module*) and the Magi wiki (below).

## How it operates

Two moving parts (`README.md:56`):

- **Discovery** — `flake.nix` hands *every* `.nix` under `modules/` to *every* host via `listFilesRecursive`. There is no import list. A leading `_` on a filename hides it from discovery.
- **Gating** — since "imported" no longer means "active", each module wraps its `config` in `lib.mkIf <flag>`, off by default. A host turns a feature on by *setting a flag*, never by importing a file.

Layout:

- `modules/nucleus/` — the floor. No flag, so it applies on every host unconditionally (boot, users, network, ssh, sops, tailscale, base packages).
- `modules/dendrites/` — one feature per file, asleep until a flag wakes it. `<feature>/` subdirs hold role-shared bits.
- `modules/aggregations.nix` — declares role flags `dx.aggregations.{desktop,hyprland,gaming,server}`.
- `hosts/<name>/` — `default.nix` imports only `./hardware.nix`, then flips `dx.*` flags. No module imports.

## Making / configuring a module

Drop the file under `modules/` — discovery imports it. Then pick **one** gate (`README.md:168`):

- **Own flag** — `options.dx.<name>.enable = lib.mkEnableOption "<name>";` then `config = lib.mkIf config.dx.<name>.enable {…}`. Flip per host. (`bluetooth.nix`)
- **Ride a role** — no own option; `config = lib.mkIf config.dx.aggregations.<role> {…}`. Wakes with the aggregation. (`kitty.nix`)
- **Always-on** — no `mkIf`; applies everywhere like the nucleus. (`git.nix`)

A single dendrite can carry both system and home config: put the NixOS options *and* a `home-manager.users.${username}` block inside the same `mkIf`.

**Never** edit `flake.nix` or any imports list to add a module — discovery handles it. A brand-new role goes in `modules/aggregations.nix`. To shelve a file without deleting it, prefix its name with `_`.

## Secrets (sops-nix)

`modules/nucleus/sops.nix` wires it: each host decrypts with its **own SSH host key** (`ssh-to-age`), so no private key is ever copied around. To use a secret:

1. Ensure the host's `ssh-to-age` pubkey is a recipient in `.sops.yaml` (already covers all three hosts). After changing recipients, re-encrypt: `sops updatekeys secrets/<name>.yaml`.
2. Store the encrypted payload in `secrets/<name>.yaml` (`sops secrets/<name>.yaml` to edit).
3. Consume it in a module: `sops.secrets."<name>".sopsFile = ../../secrets/<name>.yaml;`, then read the decrypted path at `config.sops.secrets."<name>".path`. For string interpolation, render a `sops.templates` entry with `config.sops.placeholder."<name>"`.

## Verify

```sh
nixfmt <file>.nix                          # format (repo style)
nix flake check                            # evaluate all hosts
sudo nixos-rebuild switch --flake .#<name> # apply to a host
```

Prefer `nix eval .#nixosConfigurations.<name>.config…` to confirm a change lands on the intended host before rebuilding.

## Deeper reference

Start with `README.md`. For the fuller picture, the Magi vault's `03 Homelab` wiki:

- `~/Magi/06 • MAGI-WIKI/03 Homelab/concepts/dxflake-Architecture.md` — *why* the layout is shaped this way (auto-discovery, nucleus/dendrites, the scoping decision).
- `~/Magi/06 • MAGI-WIKI/03 Homelab/concepts/dxflake-Authoring.md` — the practical how-to (where things belong, add-a-host, add-a-module, per-host divergence).
- `~/Magi/06 • MAGI-WIKI/03 Homelab/notes/Build-Runbook.md` — Phase 0 covers sops setup and adding a host.
