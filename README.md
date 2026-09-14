<h2 align="center">dxflake</h2>

<p align="center">
  <img src="https://i.imgur.com/2ZrAXlX.png" width="500px">
</p>

---

## Architecture overview

A composable, scalable, and natural architecture

> _Nyaa._ A snowflake does not _decide_ to become a snowflake ❄︎ no more than I decided to become a cat! (I did not. I am Chiyo-chan's father.) It begins at one frozen point — the **nucleus** — and from there it grows arms it never planned. This flake is the same. Do not be afraid. …Won't you stay for dinner? There will be red things. ฅ^•ﻌ•^ฅ

Modules split by *capability*, not by host. `modules/default.nix` is a **catalogue** — one `name = ./path;` line per capability — and a host writes a *selection*, not an import list. Selection is resolved first, by an ordinary `lib.evalModules` pass that knows nothing about NixOS; only what that pass resolved is then imported. No `if hostname ==` ladders, and nothing walks the filesystem.

```
dxflake/
├── flake.nix                 # inputs, the Aoide seam, one line per host
├── lib/composition.nix       # the two-pass constructor: resolve selection, then import
├── hosts/
│   ├── chiyo/                # laptop · Intel iGPU
│   ├── osaka/                # workstation · AMD GPU
│   ├── sakaki/               # headless server
│   └── yomi-strix/           # desktop · Strix Halo
│       ├── default.nix       #   a selection, then this host's own `nixos` block
│       └── hardware.nix
├── users/
│   └── khoa.nix              # ONE shared account — `nixos` lane + `homeManager` lane
├── modules/
│   ├── default.nix           # THE CATALOGUE. one `name = ./path;` line per capability
│   ├── nucleus/              # the floor. no flag — so it applies always, everywhere.
│   │   ├── system.nix · networking.nix · security.nix · boot.nix
│   │   └── packages.nix · openssh.nix · sops.nix · tailscale.nix · postgresql.nix · avahi.nix
│   └── dendrites/            # one file per capability, exposing the lanes it supports
│       ├── default.nix       #   imports the groups below. nothing else lives here
│       ├── git.nix · btop.nix · yazi.nix …    #   { homeManager = …; }
│       ├── bluetooth.nix · syncthing.nix …    #   { nixos = …; }
│       ├── openai.nix                         #   { nixos = …; homeManager = …; }
│       ├── gpu/                               #   a provider registry — amd.nix · intel.nix
│       ├── base/ desktop/ gaming/ hyprland/   #   a GROUP each: gate + both halves
│       └── _shelved.nix      #   no catalogue line — parked, not deleted
├── tests/selection/          # the constructor's executable schema
├── pkgs/                     # custom derivations
├── secrets/                  # sops-encrypted
├── assets/                   # wallpapers, screenshots
└── scripts/                  # runtime shell scripts (keybinds, sink switcher)
```

> **The nucleus.** _At the heart of every flake sits a thing that cannot be removed — like my love of tomatoes._ `modules/nucleus/` is that floor beneath every machine: the system, the network, the secrets that keep the night out, the developer's claws— er, _tools._ You do not _choose_ the nucleus. It wears no flag, and so it simply _is_ — on every machine, always. Eat your tomatoes, Chiyo. Nyan. (=^･ω･^=)

`nucleus/` is the floor every host gets unconditionally — boot, network, ssh, secrets, dev tools. It is not in the catalogue and declares no toggle, so it always applies. Ungated *is* what makes it the nucleus. The account is not floor: it lives in `users/khoa.nix`, one shared definition a host *attaches* (`users.khoa.definition = ../../users/khoa.nix`), carrying `users.users.<name>` in its `nixos` lane and the home floor in its `homeManager` lane. There are no per-host copies.

> **The dendrites.** _From the frozen center, the arms reach outward — at Mach 100._ Each is one idea only — `bluetooth.nix`, `git.nix`, `waybar.nix` — _purr._ An arm that touched every machine would smother them all, so each one **sleeps** until it is named. Lean close, whiskers and all — an arm may have two paws, one for the **system** and one for the **home**, and each paw is called by name. Neither drags the other along. A dendrite never asks _"which machine am I for?"_ It waits to be selected. This is the way. Nyaa. (=ↀωↀ=)✧

A dendrite is one capability, one file, exposing the lanes it supports: `{ nixos = …; }`, `{ homeManager = …; }`, or both. Selecting it for the system imports its `nixos` lane; selecting it under a user imports its `homeManager` lane. Neither installs the other, and asking for a lane a dendrite does not expose is an error that names the dendrite, the scope, and the lanes it does have. A capability with several implementations is a directory whose `default.nix` lists `providers = { … }` and imports none of them — `gpu` is the worked example, and the unchosen `amd.nix`/`intel.nix` is never read.

`stylix` is the one capability every host selects whether or not it paints: Aoide's facets probe `options ? stylix` to decide whether to skip colour derivation, so the option tree must exist everywhere while `dx.stylix.enable` alone decides whether dxflake's own theme applies.

> **The aggregations.** _Sometimes many arms must wake as one — the way the government pays me to deliver presents to all the children in Japan, in a single night._ `base`, `desktop`, `hyprland`, `gaming` each keep one small house of their own under `modules/dendrites/`, and every house holds its own word, its own list for the **machine** and its own list for the **person**. Say the word over a machine and its system arms wake; say the same word over a person and that person's home arms wake. One word, two halves, one place to look. …Purr-fect, is it not. Nyan! ≽^•⩊•^≼

An aggregation is shared membership plus the preferences that belong with it, and it owns its own directory: `modules/dendrites/desktop/default.nix` declares `aggregation.desktop.enable`, gates itself with `mkIf`, and lists both halves of its membership. `aggregation.desktop.enable = true` on a host selects desktop's *system* members; `users.khoa.aggregation.desktop.enable = true` selects its *home* members for that person — the same file, evaluated a second time, telling the two apart by the `scope` argument the constructor hands it. `modules/dendrites/default.nix` imports the groups and does nothing else. Membership is `mkDefault`, so a host's own `enable = false` beats it, and two groups that default the same option to different values collide rather than letting import order pick a winner.

Two kinds of `default.nix` live under `modules/dendrites/`, and they never overlap: one **named by the catalogue** is an implementation, one **imported by `modules/dendrites/default.nix`** is a group. `hyprland/` shows both — the compositor is `hyprland/compositor.nix`, catalogued as `hyprland`, and `hyprland/default.nix` is the group that selects it.

> **The hosts.** _And so a machine is no longer a long and tiresome confession — only a handful of wishes spoken aloud._ A host names its hardware, then *wishes* — the aggregations and lone arms it wants, for the machine and for the person sitting at it. `sakaki` wishes only `base`, and purrs softly. `osaka` wishes desktop, hyprland, gaming — and does not tire. Read the wishes, and you will know the machine's dreams. ﻌ ฅ(=・ﻌ・=)ฅ

A host file is a *selection* — `aggregation`, `dendrites`, `users` — followed by its own `nixos` block: hardware imports, the `dx.*` knobs for what genuinely varies, host-only overlays and packages. A host names no module file. Nothing outside `modules/default.nix` ever does.

Chiyo enables its SSH tunnel through `dx.cloudflared`. This flake provides no CSC (FAU) manual tunnel token module or `dx.cscToken` option.

> _To give a thing to every machine, drop it in the **nucleus** and give it no flag. To give it to only some, write its name in the **catalogue** and let a machine — or a person — select it. To take a thing away entirely, strike its catalogue line; the file may go on sleeping on disk. Never again ask a meow-dule who it belongs to._ …That is all. I must go now — I can fly, you know. At Mach 100. Nyaaa~ =^ｪ^= ⌒☆ 🐾💨

**The two moving parts, plainly:**

- **Catalogue** — `modules/default.nix`, one `name = ./path;` line per capability, and no registry file beside it. It generates `dendrites.<name>.enable` and `.provider`, so an unknown name fails as an option that does not exist, naming the file that asked for it. A capability with no catalogue line is unreachable — that is what shelving means now.
- **Selection** — resolved *before* any platform module graph exists, because `mkDefault` sets definition priority and cannot decide imports, and `mkIf` cannot keep an imported module's declarations out of the graph that imported them. Pass one is an ordinary `lib.evalModules` over enable/provider options; pass two imports only what it resolved, so an unselected file is never read. A `dx.*` option still gates the knobs that genuinely vary (`caddy.sites`, `nas-mounts.mounts`, …), never whether the file is reached at all.

To shelve a capability without deleting it, strike its catalogue line; the file conventionally keeps its `_`-prefixed name, e.g. `_foo.nix`, as a visual marker.

---

## Not the *pure* dendritic pattern

This flake *is* dendritic — one file per capability, each carrying its own lanes, and the import list is written rather than discovered: `modules/default.nix` names exactly the capabilities that exist, one line each. That is the dendritic essence, and this flake has it, on an **explicit catalogue plus selection** rather than automatic enumeration. What it is **not** is the [*pure* dendritic pattern](https://github.com/mightyiam/dendritic) ([FAQ](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/FAQ#dendritic-pattern-seems-just-like-a-buzzword-why-is-this-different-from-what-im-already-doing-for-the-configuration-of-my-hosts)): it stops one pillar short. Where they part is the foundation:

| | this flake (catalogue + selection) | dendritic pattern |
|---|---|---|
| Foundation | `nixpkgs.lib.nixosSystem`, behind a two-pass constructor | `flake-parts` |
| Discovery | an explicit catalogue, one line per capability, in `modules/default.nix` | `import-tree` |
| Auto-wiring **scope** | feeds `nixosConfigurations` **only** | one file registers into every output — `nixos` + `homeManager` + `perSystem` packages, devShells |
| Scoping to a host | selection, resolved before any import | options / selection |
| System + home | one dendrite exposes a `nixos` lane, a `homeManager` lane, or both; each is selected on its own | one file registers into both module classes |

The difference is **pillar 2.** This flake takes pillar 1's shape — the import list is data, not a directory walk — by hand, one catalogue line per capability, with no new dependency (`lib.filesystem.listFilesRecursive` still ships in nixpkgs; this flake calls it nowhere — even the upstream Aoide songs are named one by one in `flake.nix`). Pillar 2 is `flake-parts`: a single file registering into *many* flake outputs at once (packages, devShells, multi-arch `perSystem`, whole configs). Taking it means a paradigm change (`nixosSystem → flake-parts`) plus `import-tree`, and it only pays off across outputs a single-target NixOS config doesn't ship. The "one dendrite reaches system + home" here works because the constructor hands each lane to the evaluator that asked for it and Home Manager rides the NixOS module, not because a multi-output module system sits underneath.

---

## Install:

Requires NixOS with flakes enabled (`nix.settings.experimental-features = [ "nix-command" "flakes" ];`).

A host is a folder under `hosts/<name>/`: a generated `hardware.nix` and a `default.nix` holding this machine's selection. The nucleus reaches every host with nothing named; everything else is reached only when the host — or a user attached to it — selects it by catalogue name.
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

3. Write `hosts/<name>/default.nix` — a selection, then this host's own settings. The account comes from `users/khoa.nix`; you attach it, you do not copy it:

   ```nix
   {
     aggregation = {
       base.enable = true;        # the machine's half: stylix
       desktop.enable = true;     # audio, fonts, portals, login …
     };

     dendrites = {
       bluetooth.enable = true;
       gpu = {
         enable = true;
         provider = "intel";      # the amd file is never imported here
       };
     };

     users.khoa = {
       definition = ../../users/khoa.nix;
       homeManager.enable = true;
       aggregation = {
         base.enable = true;      # the person's half: bash, git, neovim …
         desktop.enable = true;
       };
     };

     nixos = {
       imports = [ ./hardware.nix ];
       boot.initrd.kernelModules = [ "nvme" ];
     };
   }
   ```

4. Add the name to the host list in `flake.nix` — that is the whole registration:

   ```nix
   hosts = lib.genAttrs [ "chiyo" "osaka" "sakaki" "yomi-strix" "<name>" ] (name: …);
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

Osaka and yomi-strix enable the upstream `aoide.openai` dendrite for the Codex CLI and official ChatGPT Linux desktop; osaka pairs it with its Aoide session tracking, yomi-strix manages the rest of its Aoide integration from its own flake at ~/Aoide.

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

Write the file under `modules/dendrites/`, add one line to the catalogue in `modules/default.nix`, and select it. The whole job: **write the file → catalogue it → select it.** You never edit `flake.nix`.

A dendrite is an attrset of **lanes**, one per evaluator. A **system** capability:

```nix
{
  nixos = { ... }: {
    services.foo.enable = true;
  };
}
```

A **home** capability — the same shape, the other lane:

```nix
{
  homeManager = { pkgs, ... }: {
    programs.foo.enable = true;
  };
}
```

A capability that can answer either way carries both, and each is selected on its own — putting `foo` in a host's `dendrites` installs the system lane, putting it in `users.khoa.dendrites` installs the home lane, and neither drags the other in:

```nix
{
  nixos = { pkgs, ... }: { environment.systemPackages = [ pkgs.foo ]; };
  homeManager = { pkgs, ... }: { home.packages = [ pkgs.foo ]; };
}
```

A capability with several implementations is a **directory** whose `default.nix` lists them and imports none:

```nix
# modules/dendrites/gpu/default.nix
{
  providers = {
    amd = ./amd.nix;
    intel = ./intel.nix;
  };
}
```

Then `gpu = { enable = true; provider = "amd"; }` on the host — `intel.nix` is never read.

**Two kinds of module, by what they need from a host:**
- **Selected = active** — no `options.dx.<name>.enable` at all; the lane applies the moment it is selected, and dropping the selection is how a host opts out. (`bluetooth.nix`, `aoide.nix`, and every capability with no knobs of its own)
- **`dx.` knobs for what genuinely varies** — a capability some hosts configure differently keeps `options.dx.<name>.<knob>` for that variance only, never for whether it runs (`caddy.sites`, `cloudflared.tunnelId`/`hostnames`, `immich.mediaLocation`, `inference.igpu`, `nas-mounts.server`/`mounts`).

Aggregations follow the same rule one level up: a group's `default.nix` names each member once, in the `scope` branch that matches the lane it rides, and a host or a user says the word.

**What you never touch:** `flake.nix`, or any module path outside `modules/default.nix` — the catalogue is the only place a capability file is named. Need a new aggregation? Add a directory under `modules/dendrites/` whose `default.nix` declares its `aggregation.<name>.enable` and both membership branches, then one import line in `modules/dendrites/default.nix`. Want to park a capability without deleting it? Strike its catalogue line.

**Prove it still holds:**

```sh
nix eval --json .#inventory.<host> | jq   # what this host resolved, and from where
./tests/selection/run.sh                  # the constructor's executable schema
```

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
- multihost (chiyo + osaka + sakaki + yomi-strix)
- sops-nix secrets
- jellyfin + steam + aagl on osaka
- one-line new-host: a name in the catalogue-driven host list
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
