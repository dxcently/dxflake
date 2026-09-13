<h2 align="center">dxflake</h2>

<p align="center">
  <img src="https://i.imgur.com/2ZrAXlX.png" width="500px">
</p>

---

## Architecture overview

A composable, scalable, and natural architecture

> _Nyaa._ A snowflake does not _decide_ to become a snowflake ❄︎ no more than I decided to become a cat! (I did not. I am Chiyo-chan's father.) It begins at one frozen point — the **nucleus** — and from there it grows arms it never planned. This flake is the same. Do not be afraid. …Won't you stay for dinner? There will be red things. ฅ^•ﻌ•^ฅ

Modules split by *scope*, not by host — a floor everyone gets, shared aggregates a host selects, and singles a host selects on their own. Each directory names its own files in one `default.nix`; `flake.nix` imports the single pointer `./modules`, which reaches only the floor. A host imports the shared aggregate directories and single dendrites it wants — no `if hostname ==` ladders, but a host file is exactly where a module gets named from outside its own directory.

```
dxflake/
├── flake.nix                 # the registry. imports ./modules, summons a machine in one line.
├── hosts/
│   ├── chiyo/                # laptop · Intel iGPU
│   ├── osaka/                # workstation · AMD GPU
│   └── sakaki/               # headless server
├── modules/                  # default.nix names nucleus/ + dendrites/, into every host
│   ├── nucleus/              # the floor. no flag — so it applies always, everywhere.
│   │   ├── system.nix · networking.nix · user.nix · security.nix · boot.nix
│   │   └── packages.nix · openssh.nix · sops.nix · tailscale.nix · postgresql.nix · avahi.nix
│   └── dendrites/            # default.nix lists only the floor dendrites below
│       ├── bash.nix · btop.nix · direnv.nix · git.nix · mcfly.nix · neovim.nix · nh.nix
│       ├── starship.nix · stylix.nix · yazi.nix  #   always-on; stylix's option TREE must
│       │                                          #   ride every host (Aoide's own probe)
│       ├── <feature>.nix     #   a host-selected single — bluetooth, kitty, hyprlock …
│       ├── desktop/ hyprland/ gaming/ server/  #   shared aggregates; each names its own
│       │                                       #   files in its own default.nix
│       └── _shelved.nix      #   no line anywhere — parked, not deleted
├── pkgs/                     # custom derivations
├── secrets/                  # sops-encrypted
├── assets/                   # wallpapers, screenshots
└── scripts/                  # runtime shell scripts (keybinds, sink switcher)
```

> **The nucleus.** _At the heart of every flake sits a thing that cannot be removed — like my love of tomatoes._ `modules/nucleus/` is that floor beneath all three machines: the system, the network, the user, the secrets that keep the night out, the developer's claws— er, _tools._ You do not _choose_ the nucleus. It wears no flag, and so it simply _is_ — on every machine, always. Eat your tomatoes, Chiyo. Nyan. (=^･ω･^=)

`nucleus/` is the floor every host gets unconditionally — boot, users, network, ssh, secrets, dev tools. It is named like everything else, in `nucleus/default.nix`, but declares no toggle, so it always applies. Ungated *is* what makes it the nucleus.

> **The dendrites.** _From the frozen center, the arms reach outward — at Mach 100 — but only the always-on few reach every machine._ Each is one idea only — `bluetooth.nix`, `git.nix`, `waybar.nix` — _purr._ An arm that touches every machine would smother them all, so beyond the floor, each one **sleeps** until its machine names it. Lean close, whiskers and all — a single sleeping arm reaches into two worlds at once, one paw the **system**, one paw the **home**, both waking on the same import. A dendrite never asks _"which machine am I for?"_ It waits to be named. This is the way. Nyaa. (=ↀωↀ=)✧

The floor's dendrites are imported into *every* host; a single dendrite beyond the floor is one feature, one file, imported only by the hosts that select it, carrying its system config, its home-manager config, or both, in the same `config` block. One file, both layers, one import.

> **The aggregations.** _Sometimes many arms must wake as one — the way the government pays me to deliver presents to all the children in Japan, in a single night._ `desktop`, `hyprland`, `gaming`, `server` are folders now, not words — shared aggregate directories under `modules/dendrites/`. Import one directory on a host and every arm inside it wakes together. One directory, many arms — each still carrying its own two worlds. …Purr-fect, is it not. Nyan! ≽^•⩊•^≼

An aggregation is a **shared directory**, not a role flag. `modules/dendrites/{desktop,hyprland,gaming,server}/default.nix` each name their own member files, one line apiece; a host that wants the bundle imports the directory itself (`../../modules/dendrites/desktop`), never a file inside it. Import the directory once on a host and every member lights up.

> **The hosts.** _And so a machine is no longer a long and tiresome confession — only a handful of wishes spoken aloud._ A host names its hardware, then imports the aggregates and singles it wants. `sakaki` wishes only `server`, and purrs softly. `osaka` wishes desktop, hyprland, gaming — and does not tire. Read the wishes, and you will know the machine's dreams. ﻌ ฅ(=・ﻌ・=)ฅ

A host file = `imports = [ ./hardware.nix ]`, plus the shared aggregate directories and single dendrites this host selects (`../../modules/dendrites/<x>`), then a short set of `dx.*` knobs for what genuinely varies (plus any host-only odds inline). A host file is the one place a module is ever named from outside the directory that holds it.

Chiyo enables its SSH tunnel through `dx.cloudflared`. This flake provides no CSC (FAU) manual tunnel token module or `dx.cscToken` option.

> _To give a thing to every machine, drop it in the **nucleus** and give it no flag. To give it to only some, put it behind a **shared aggregate** or leave it a lone single, and let a host import it by name. To take a thing away entirely, hush its name with a `_`. Never again ask a meow-dule who it belongs to._ …That is all. I must go now — I can fly, you know. At Mach 100. Nyaaa~ =^ｪ^= ⌒☆ 🐾💨

**The two moving parts, plainly:**

- **Aggregation** — each directory names its own files in its own `default.nix`, one line per file; a directory with subdirectories imports each once (`./desktop`, never `./desktop/packages.nix` from outside it). `flake.nix` imports one pointer, `./modules`, which reaches only the floor.
- **Selection** — a shared aggregate directory or a single dendrite is inert until some host imports it; a host's own `default.nix` is the one place that names a module from outside the directory that holds it. A `dx.*` option still gates the knobs that genuinely vary (`caddy.sites`, `nas-mounts.mounts`, …), never whether the file is reached at all.

To shelve a module without deleting it, drop its line from the directory's `default.nix` (it conventionally keeps its `_`-prefixed name, e.g. `_foo.nix`, as a visual marker).

---

## Not the *pure* dendritic pattern

This flake *is* dendritic — one file per feature, each gating itself by option, and the import list *is* the filesystem: every directory's own `default.nix` names exactly the files it holds, one line each. That is the dendritic essence, and this flake has it, on **explicit aggregation** rather than automatic enumeration. What it is **not** is the [*pure* dendritic pattern](https://github.com/mightyiam/dendritic) ([FAQ](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/FAQ#dendritic-pattern-seems-just-like-a-buzzword-why-is-this-different-from-what-im-already-doing-for-the-configuration-of-my-hosts)): it stops one pillar short. Where they part is the foundation:

| | this flake (explicit aggregation) | dendritic pattern |
|---|---|---|
| Foundation | `nixpkgs.lib.nixosSystem` | `flake-parts` |
| Discovery | explicit `default.nix` aggregates, one line per file, over `modules/` | `import-tree` |
| Auto-wiring **scope** | feeds `nixosConfigurations` **only** | one file registers into every output — `nixos` + `homeManager` + `perSystem` packages, devShells |
| Scoping to a host | option flags (`dx.*`) | options / selection |
| System + home | one dendrite carries both, via `home-manager.users.${username}` | one file registers into both module classes |

The difference is **pillar 2.** This flake takes pillar 1's shape — the import list mirrors the tree — by hand, one `default.nix` line per file, with no new dependency (`lib.filesystem.listFilesRecursive` still ships in nixpkgs; here it only serves the upstream Aoide input's songbook, not this flake's own `modules/`). Pillar 2 is `flake-parts`: a single file registering into *many* flake outputs at once (packages, devShells, multi-arch `perSystem`, whole configs). Taking it means a paradigm change (`nixosSystem → flake-parts`) plus `import-tree`, and it only pays off across outputs a single-target NixOS config doesn't ship. The "one dendrite reaches system + home" here works because `home-manager.users.${username}` is a NixOS option, not because a multi-output module system sits underneath.

---

## Install:

Requires NixOS with flakes enabled (`nix.settings.experimental-features = [ "nix-command" "flakes" ];`).

A host is a folder under `hosts/<name>/` with two files: a generated `hardware.nix` and a `default.nix` that imports the aggregates and singles this machine wants. The floor reaches every host through `modules/default.nix` (`nucleus/` and the floor of `dendrites/`) with no host import needed; a shared aggregate directory or a single dendrite beyond the floor is reached only when a host names it in its own `imports`.
Swap `<name>` for your host — it becomes the flake target.

1. Clone the repo:

   ```sh
   git clone https://github.com/dxcently/dxflake ~/dxflake
   cd ~/dxflake
   ```

2. Generate `hardware.nix` (run on the target machine; pipes to stdout, so nothing else is touched):

   ```sh
   mkdir -p hosts/<name>
   sudo nixos-generate-config --show-hardware-config > hosts/<name>/hardware.nix
   ```

3. Write `hosts/<name>/default.nix` — import the hardware, the shared aggregates and single dendrites this host wants (the nucleus comes for free, no import needed):

   ```nix
   {...}: {
     imports = [
       ./hardware.nix
       ../../modules/dendrites/desktop    # a shared aggregate — wakes a bundle of dendrites
       ../../modules/dendrites/hyprland
       ../../modules/dendrites/bluetooth.nix  # a single feature
       ../../modules/dendrites/gpu-intel.nix
     ];

     # host-only odds and ends go inline:
     boot.initrd.kernelModules = [ "nvme" ];
   }
   ```

4. Register it in `flake.nix` under `nixosConfigurations`, and set `username` to yours:

   ```nix
   username = "<user>"; 

   nixosConfigurations = {
     <name> = mkHost "<name>";
   };
   ```

5. Rebuild, then reboot:

   ```sh
   sudo nixos-rebuild switch --flake .#<name>
   ```

---

## Commands

```sh
# rebuild + activate + set as boot default
dxrebuild        # nh os switch /home/khoa/dxflake/

# same, but bump flake.lock first
dxupdate         # nh os switch /home/khoa/dxflake/ --update

# build + set as boot default, don't activate now
dxboot           # nh os boot /home/khoa/dxflake/

# build + activate, don't persist as boot default
dxtest           # nh os test /home/khoa/dxflake/

# build only, no activation — compile check
dxbuild          # nh os build /home/khoa/dxflake/

# revert to the previous generation
dxrollback       # nh os rollback

# evaluate every nixosConfiguration, catch errors before building
dxcheck          # nix flake check /home/khoa/dxflake/

# list generations
dxgens           # nh os info

# generation cleanup (wraps nix-collect-garbage)
dxclean          # nh clean all

# cd straight into the flake repo
dx               # cd /home/khoa/dxflake

# power
reboot           # systemctl reboot
shutdown         # systemctl poweroff
poweroff         # systemctl poweroff
sleep            # systemctl suspend
hibernate        # systemctl hibernate
lock             # hyprlock
```

## Aoide directional trust (runtime)

Aoide runtime is wired from the pinned Aoide input by binding the core subflake as
`inputs.aoide = inputs.aoide.inputs.aoide`, then importing the upstream module
aggregate once via `modules/default.nix`.

Osaka enables the upstream `aoide.openai` dendrite for the Codex CLI and official ChatGPT Linux desktop alongside its Aoide session tracking.

Aoide node grants (`read`/`message`/`spawn`) are runtime-owned in this repo.
Each receiving host grants only the other two peers:

| Host       | Peers to allow |
|------------|----------------|
| Yomi       | osaka, sakaki  |
| Osaka      | yomi-strix, sakaki |
| Sakaki     | yomi-strix, osaka |

Apply them on the receiving host with:

- `aoide node allow <peer> read on`
- `aoide node allow <peer> message on`
- `aoide node allow <peer> spawn on`

Those grants are not applied from this flake.

## Livery -> theme flow and ownership

On hosts that keep dxflake Hyprland behavior but enable `aoide.facets.stylix.enable`
(for example Osaka), AOIDE owns baked theme ownership:

- AOIDE resolves `aoide.livery` into a full scheme through upstream `lib/livery.nix`.
- `stylix.base16Scheme` and `stylix.polarity` stay owned by AOIDE in that mode.
- `modules/dendrites/stylix.nix` still provides dxflake font/cursor/icons and
  fixed targets for non-color assets, but does not override colors or polarity
  when AOIDE Stylix is active.
- `modules/dendrites/hyprland/default.nix` derives active/inactive borders from
  the resolved livery under AOIDE ownership, otherwise keeps historical RGBA.

Hosts without AOIDE Stylix ownership keep non-lyra fallback:

- `stylix` remains fixed Rosé Pine + `dark` polarity.
- Hyprland borders remain:
  - `col.active_border = rgba(ffffff99)`
  - `col.inactive_border = rgba(000000cc)`

Host-only tests are still done as eval-only overrides (no file changes): use an
`extendModules` eval to set `config.aoide.livery.override.accent` and confirm both:

- `config.stylix.base16Scheme.<slot>` (for authored-color propagation)
- `config.home-manager.users.khoa.wayland.windowManager.hyprland.settings.general."col.active_border"`

---

## Adding a module

Drop a `.nix` under `modules/dendrites/` (or the feature's own subdirectory) and add its line to that directory's `default.nix` — you never edit `flake.nix`. The whole job: **write the file → list it → gate it → flip the flag on a host.**

A **system (NixOS)** module — its own switch, config at the system level:

```nix
{config, lib, ...}: {
  options.dx.foo.enable = lib.mkEnableOption "foo";
  config = lib.mkIf config.dx.foo.enable {
    services.foo.enable = true;
  };
}
```

A **home-manager** module — same gate, config nested under the user:

```nix
{username, config, lib, ...}: {
  options.dx.foo.enable = lib.mkEnableOption "foo";
  config = lib.mkIf config.dx.foo.enable {
    home-manager.users.${username} = {pkgs, ...}: {
      programs.foo.enable = true;
    };
  };
}
```

Either way the host just speaks the word — `dx.foo.enable = true;`. One dendrite can carry **both** layers: put the system options *and* the `home-manager.users.${username}` block inside the same `mkIf` — one file, one switch, both worlds.

**Three ways to reach a host**, pick per module:
- **Own flag** — declare `options.dx.<name>.enable`, gate on it, and have the host that wants it import the file. (`bluetooth.nix`)
- **Ride a shared aggregate** — no own option; the file lives inside `desktop/`, `hyprland/`, `gaming/`, or `server/` and its `default.nix` names it. Wakes when a host imports the directory. (`kitty.nix`)
- **Always-on** — no `mkIf` at all, listed in the floor's `dendrites/default.nix`; it applies everywhere like the nucleus. (`git.nix`)

**What you never touch:** `flake.nix`, or another directory's `default.nix` — a file is only ever named from inside the directory that holds it, except a host's own `default.nix`, which is the one place that names a module from outside. Need a brand-new shared aggregate? Add the directory under `modules/dendrites/` and have the hosts that want it import it. Want to park a file without deleting it? Drop its line from the directory's `default.nix`.

---

## What's in here:
- hyprland + waybar + awww
- hyprlock + wlogout
- yazi + thunar file browser
- rofi launcher
- dunst notifications
- hyprshot + satty screenshots
- bash + kitty
- neovim (nvf)
- stylix theming
- fcitx5 input method
- multihost (chiyo + osaka + sakaki)
- sops-nix secrets
- jellyfin + steam + aagl on osaka
- one-line new-host via `mkHost`
- functional (kind of)
- looks pretty. I think
- _does not come with fl studio_
- OH MAH GAH!

---

## Screenshots:

<details>
<summary><b>04.04.24 / yuyo v1</b></summary>

![image](./assets/screenshots/yuyo.png)

</details>

<details>
<summary><b>21.04.24 / yuyo v2</b></summary>

![image](./assets/screenshots/yuyo2.png)

</details>

<details>
<summary><b>03.06.24 /『🍓』strawberry flavored</b></summary>

![image](./assets/screenshots/strawbf.png)
![image](./assets/screenshots/strawbf1.png)
![image](./assets/screenshots/strawbf2.png)

</details>

<details>
<summary><b>22.02.25 / 𝄞 v1</b></summary>

![image](./assets/screenshots/musicsavesmysoul.png)

</details>

<details>
<summary><b>12.03.25 / 𝄞 v2</b></summary>

![image](./assets/screenshots/musicsavesmysoul1.png)
![image](./assets/screenshots/musicsavesmysoul2.png)

</details>

<details>
<summary><b>04.04.25 / 𝄞 v3</b></summary>

![image](./assets/screenshots/ohmahgah.png)

</details>

<details open>
<summary><b>09.25.25 / 𝄞 v4</b></summary>

![image](./assets/screenshots/notev4.png)

</details>

---

## Credit to other flakes/rices I've referenced:

- [Ruixi-rebirth/flakes](https://github.com/Ruixi-rebirth/flakes)
- [Zaney/zaneyos](https://gitlab.com/Zaney/zaneyos/-/tree/main?ref_type=heads)
- [iynaix/dotfiles](https://github.com/iynaix/dotfiles/tree/main)
- [fvwm — my love letter (r/unixporn)](https://www.reddit.com/r/unixporn/comments/1cyujs8/fvwm_my_love_letter/#lightbox)
- [Frost-Phoenix/nixos-config](https://github.com/Frost-Phoenix/nixos-config)
- and many more i can't list here, thank you all <3

---

> When you create something, *you* created it.
> 
> /ᐠ - ˕ -マ Ⳋ ⋆˚✿˖°
