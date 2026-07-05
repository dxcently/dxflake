<h2 align="center">dxflake</h2>

<p align="center">
  <img src="https://i.imgur.com/2ZrAXlX.png" width="500px">
</p>

---

## Architecture overview

A composable, scalable, and natural architecture

> _Nyaa._ A snowflake does not _decide_ to become a snowflake ❄︎ no more than I decided to become a cat! (I did not. I am Chiyo-chan's father.) It begins at one frozen point — the **nucleus** — and from there it grows arms it never planned. This flake is the same. Do not be afraid. …Won't you stay for dinner? There will be red things. ฅ^•ﻌ•^ฅ

Modules split by *scope*, not by host — a floor everyone gets, opt-in features, and roles that bundle them. `flake.nix` finds every module by itself; a host just *flips the flags* it wants — no import lists, no `if hostname ==` ladders.

```
dxflake/
├── flake.nix                 # the registry. discovers every module, summons a machine in one line.
├── hosts/
│   ├── chiyo/                # laptop · Intel iGPU
│   ├── osaka/                # workstation · AMD GPU
│   └── sakaki/               # headless server
├── modules/                  # ← flake.nix imports EVERY .nix in here, into every host
│   ├── nucleus/              # the floor. no flag — so it applies always, everywhere.
│   │   ├── system.nix · networking.nix · user.nix · security.nix · boot.nix
│   │   └── packages.nix · openssh.nix · sops.nix · tailscale.nix · postgresql.nix · avahi.nix
│   ├── aggregations.nix      # declares the role flags: dx.aggregations.{desktop,hyprland,gaming,server}
│   └── dendrites/            # the optional limbs — imported everywhere, asleep until a flag wakes them
│       ├── <feature>.nix     #   one feature, one file — bluetooth, git, kitty, stylix …
│       ├── desktop/ hyprland/ gaming/  #   role-shared bits (packages + the odd shared knob)
│       └── _shelved.nix      #   a leading _ hides a file from discovery — parked, not deleted
├── packages/                 # custom derivations
├── secrets/                  # sops-encrypted
└── extras/                   # wallpapers, screenshots
```

> **The nucleus.** _At the heart of every flake sits a thing that cannot be removed — like my love of tomatoes._ `modules/nucleus/` is that floor beneath all three machines: the system, the network, the user, the secrets that keep the night out, the developer's claws— er, _tools._ You do not _choose_ the nucleus. It wears no flag, and so it simply _is_ — on every machine, always. Eat your tomatoes, Chiyo. Nyan. (=^･ω･^=)

`nucleus/` is the floor every host gets unconditionally — boot, users, network, ssh, secrets, dev tools. It is discovered like everything else, but declares no toggle, so it always applies. Ungated *is* what makes it the nucleus.

> **The dendrites.** _From the frozen center, the arms reach outward — at Mach 100 — and every arm reaches every machine._ Each is one idea only — `bluetooth.nix`, `git.nix`, `waybar.nix` — _purr._ But an arm that touches every machine would smother them all, so each one **sleeps** until its machine whispers the waking word: `dx.<name>.enable = true`. Lean close, whiskers and all — a single sleeping arm reaches into two worlds at once, one paw the **system**, one paw the **home**, both waking on the same word. A dendrite never asks _"which machine am I for?"_ It reaches all of them and waits to be called. This is the way. Nyaa. (=ↀωↀ=)✧

Every module under `modules/` is imported into *every* host — so a dendrite is one feature, one file, that does nothing until a flag turns it on. It carries its system config, its home-manager config, or both, all behind the same `lib.mkIf`. One file, both layers, one switch.

> **The aggregations.** _Sometimes many arms must wake as one — the way the government pays me to deliver presents to all the children in Japan, in a single night._ `desktop`, `hyprland`, `gaming`, `server` are not folders now but *words* — role flags in `aggregations.nix`. Speak one word on a host and every arm that answers to it wakes together. One name, many arms — each still carrying its own two worlds. …Purr-fect, is it not. Nyan! ≽^•⩊•^≼

An aggregation is a **role flag**, not a bundle folder. `modules/aggregations.nix` declares `dx.aggregations.{desktop,hyprland,gaming,server}`; each dendrite that belongs to a role gates itself on it (`lib.mkIf config.dx.aggregations.desktop`). Flip the role once on a host and every member lights up.

> **The hosts.** _And so a machine is no longer a long and tiresome confession — only a handful of wishes spoken aloud._ A host names its hardware, then flips the flags it wants. `sakaki` wishes only `server`, and purrs softly. `osaka` wishes desktop, hyprland, gaming, server — and does not tire. Read the wishes, and you will know the machine's dreams. ﻌ ฅ(=・ﻌ・=)ฅ

A host file = `imports = [ ./hardware.nix ]`, then a short set of `dx.*` flags (plus any host-only odds inline). No module imports. Read the flags and you know the machine.

> _To give a thing to every machine, drop it in the **nucleus** and give it no flag. To give it to only some, gate it behind a **flag** — a role, or its own `enable` — and let a host speak the word. To take a thing away entirely, hush its name with a `_`. Never again ask a meow-dule who it belongs to._ …That is all. I must go now — I can fly, you know. At Mach 100. Nyaaa~ =^ｪ^= ⌒☆ 🐾💨

**The two moving parts, plainly:**

- **Discovery** — `flake.nix` hands every `.nix` under `modules/` to every host (`lib.filesystem.listFilesRecursive`, minus any `/_` path). No import lists to maintain.
- **Gating** — since import no longer means active, each optional module wraps its `config` in `lib.mkIf` on a flag that is off by default. A host turns a feature on by setting the flag, not by importing the file.

To hide a module from discovery without deleting it, rename it with a leading underscore (`foo.nix` → `_foo.nix`).

---

## Not the *pure* dendritic pattern

This flake *is* dendritic — with auto-discovery the filesystem **is** the import list, every module is enumerated automatically, and each gates itself by option. That is the dendritic essence, and this flake has it. What it is **not** is the [*pure* dendritic pattern](https://github.com/mightyiam/dendritic) ([FAQ](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/FAQ#dendritic-pattern-seems-just-like-a-buzzword-why-is-this-different-from-what-im-already-doing-for-the-configuration-of-my-hosts)): it stops one pillar short. Where they part is the foundation:

| | this flake (auto-discovery) | dendritic pattern |
|---|---|---|
| Foundation | `nixpkgs.lib.nixosSystem` | `flake-parts` |
| Discovery | `lib.filesystem.listFilesRecursive` over `modules/` | `import-tree` |
| Auto-wiring **scope** | feeds `nixosConfigurations` **only** | one file registers into every output — `nixos` + `homeManager` + `perSystem` packages, devShells |
| Scoping to a host | option flags (`dx.*`) | options / selection |
| System + home | one dendrite carries both, via `home-manager.users.${username}` | one file registers into both module classes |

The difference is **pillar 2.** This flake takes pillar 1 — auto-enumerate the tree — with no new dependency (`listFilesRecursive` ships in nixpkgs). Pillar 2 is `flake-parts`: a single file registering into *many* flake outputs at once (packages, devShells, multi-arch `perSystem`, whole configs). Taking it means a paradigm change (`nixosSystem → flake-parts`) plus `import-tree`, and it only pays off across outputs a single-target NixOS config doesn't ship. The "one dendrite reaches system + home" here works because `home-manager.users.${username}` is a NixOS option, not because a multi-output module system sits underneath.

---

## Install:

Requires NixOS with flakes enabled (`nix.settings.experimental-features = [ "nix-command" "flakes" ];`).

A host is a folder under `hosts/<name>/` with two files: a generated `hardware.nix` and a `default.nix` that flips the flags this machine wants. Every module in `modules/` is auto-discovered — you never import them; the nucleus applies for free, and features wait behind their flags.
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

3. Write `hosts/<name>/default.nix` — import only the hardware, then flip the flags this host wants (the nucleus comes for free; no module imports):

   ```nix
   {...}: {
     imports = [ ./hardware.nix ];

     dx.aggregations = {          # roles — each wakes a bundle of dendrites
       desktop = true;
       hyprland = true;
     };
     dx.bluetooth.enable = true;  # a single feature
     dx.gpu-intel.enable = true;

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

## Adding a module

Drop a `.nix` anywhere under `modules/` and it is already imported into every host — you never edit `flake.nix` or an imports list. The whole job is three steps: **write the file → gate it → flip the flag on a host.**

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

**Three ways to gate**, pick per module:
- **Own flag** — declare `options.dx.<name>.enable`, gate on it. Flip it per host. (`bluetooth.nix`)
- **Ride a role** — no own option; gate on an existing aggregation, `config = lib.mkIf config.dx.aggregations.desktop {…}`. Wakes with the role. (`kitty.nix`)
- **Always-on** — no `mkIf` at all; it applies everywhere like the nucleus. (`git.nix`)

**What you never touch:** `flake.nix`, any import list — discovery handles it. Need a brand-new role? Add it to `modules/aggregations.nix`. Want to park a file without deleting it? Prefix its name with `_`.

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

![image](./extras/screenshots/yuyo.png)

</details>

<details>
<summary><b>21.04.24 / yuyo v2</b></summary>

![image](./extras/screenshots/yuyo2.png)

</details>

<details>
<summary><b>03.06.24 /『🍓』strawberry flavored</b></summary>

![image](./extras/screenshots/strawbf.png)
![image](./extras/screenshots/strawbf1.png)
![image](./extras/screenshots/strawbf2.png)

</details>

<details>
<summary><b>22.02.25 / 𝄞 v1</b></summary>

![image](./extras/screenshots/musicsavesmysoul.png)

</details>

<details>
<summary><b>12.03.25 / 𝄞 v2</b></summary>

![image](./extras/screenshots/musicsavesmysoul1.png)
![image](./extras/screenshots/musicsavesmysoul2.png)

</details>

<details>
<summary><b>04.04.25 / 𝄞 v3</b></summary>

![image](./extras/screenshots/ohmahgah.png)

</details>

<details open>
<summary><b>09.25.25 / 𝄞 v4</b></summary>

![image](./extras/screenshots/notev4.png)

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
