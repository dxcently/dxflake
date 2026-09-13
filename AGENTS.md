# CLAUDE.md — dxflake

A multi-host NixOS flake (`chiyo` laptop · `osaka` workstation · `sakaki` server).
Melete (the AI agent harness, `modules/dendrites/melete.nix`) runs sakaki-only — imported there and nowhere else, pinned client v0.2.0 via `pkgs/melete-client-package.nix` (call site in the dendrite itself).
Melete's spawned agent turns use the real `claude` CLI by default (resolved from PATH via `[claude] binary = "claude"` in the out-of-band `config.toml`). The pi-agent shim (`~/.config/melete/bin/melete-agent`) is retained on disk but no longer routed to — point `[claude] binary` back at it to restore pi routing (`deepseek/deepseek-v4-pro` for coding/execution with thinking scaled by complexity, `kimi-coding/k3-256k` for planning/escalation).
This file is a **registry**: where things live and how to add them. For the *why*,
read `README.md` (*Architecture overview*, *Adding a module*) and the Magi wiki (below).

## How it operates

Two moving parts (`README.md:64`):

- **Aggregation** — each directory names its own files in its own `default.nix`, one line per file; a directory with subdirectories imports each once. `flake.nix` imports one pointer, `./modules`, which reaches only the floor. A shelved file just has no line (still `_`-prefixed by convention).
- **Selection** — the floor reaches every host for free; a shared aggregate directory or a single dendrite beyond the floor is inert until a host imports it. A host's own `default.nix` is the one place that ever names a module from outside the directory that holds it. A `dx.*` option still gates the knobs that genuinely vary, never whether the file is reached at all.

Layout:

- `modules/nucleus/` — the floor. No flag, so it applies on every host unconditionally (boot, the home-manager wiring, network, ssh, sops, tailscale, base packages, the `openldap` overlay — a fleet-wide build fix, not a host selection).
- `modules/dendrites/` — `default.nix` lists only the always-on floor dendrites plus `stylix.nix` (its option tree must ride every host, Aoide's own probe). Everything else is a host-selected single or lives in a shared aggregate directory.
- `modules/dendrites/{desktop,hyprland,gaming,server}/` — shared aggregate directories; each names its own member files in its own `default.nix`.
- `hosts/<name>/` — `default.nix` imports `./hardware.nix`, `./users/khoa.nix`, the shared aggregates and single dendrites this host wants, then sets any `dx.*` knobs and host-only odds. `hosts/<name>/users/khoa.nix` is this host's own `users.users.khoa` block and `nix.settings.allowed-users` — the one piece of the user the nucleus does not carry. A host-only overlay (e.g. osaka's `soundconverter` fix) lives beside its consumer in that host's `default.nix`, not the nucleus.

## Making / configuring a module

Drop the file under `modules/dendrites/` (or a shared aggregate subdir) and add its line to that directory's `default.nix`. Then pick **one** shape (`README.md:268`):

- **Imported = active** — no `options.dx.<name>.enable`; `config` applies unconditionally once a host imports the file, and dropping the import is the opt-out. (`bluetooth.nix`)
- **`dx.` knobs for what genuinely varies** — keep `options.dx.<name>.<knob>` only for config that differs per host, never for whether the module runs. (`caddy.sites`, `cloudflared.tunnelId`, `nas-mounts.mounts`)
- **Ride a shared aggregate** — no own option; the file lives inside `desktop/`, `hyprland/`, `gaming/`, or `server/` and that directory's `default.nix` names it. Wakes when a host imports the directory. (`kitty.nix`)
- **Always-on** — listed in the floor's `modules/dendrites/default.nix`; applies everywhere like the nucleus. (`git.nix`)

A single dendrite can carry both system and home config: put the NixOS options *and* a `home-manager.users.${username}` block inside the same `config`.

**Never** edit `flake.nix`, or name a file from outside the directory that holds it, except a host's own `default.nix` — that is the one place selection happens. A brand-new shared aggregate is a new directory under `modules/dendrites/` with its own `default.nix`; hosts that want it import it. To shelve a file without deleting it, drop its line from the directory's `default.nix`.

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
