<h2 align="center">dxflake</h2>

<p align="center">
  <img src="https://i.imgur.com/2ZrAXlX.png" width="500px">
</p>

---

## Architecture overview

A composable, scalable, and natural architecture

> _Nyaa._ A snowflake does not _decide_ to become a snowflake ❄︎ no more than I decided to become a cat! (I did not. I am Chiyo-chan's father.) It begins at one frozen point — the **nucleus** — and from there it grows arms it never planned. This flake is the same. Do not be afraid. …Won't you stay for dinner? There will be red things. ฅ^•ﻌ•^ฅ

Modules split by *capability*, not by host. `modules/default.nix` is the **registry** — a catalogue of one `name = ./path;` line per capability, plus the aggregations discovered beside it — and a host writes a *selection*, not an import list. Selection is resolved first, by an ordinary `lib.evalModules` pass that knows nothing about NixOS; only what that pass resolved is then imported. No `if hostname ==` ladders. The flake reads the filesystem in exactly one place, one level deep: `modules/aggregations/default.nix` names its own child directories and imports none of them.

```
dxflake/
├── flake.nix                 # inputs, the Aoide seam, one line per host
├── lib/composition.nix       # the constructor: gate, select, then import what survived
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
│   ├── default.nix           # THE REGISTRY. the catalogue, plus `import ./aggregations`
│   ├── nucleus/              # the floor. no flag — so it applies always, everywhere.
│   │   ├── system.nix · networking.nix · security.nix · boot.nix
│   │   └── packages.nix · openssh.nix · sops.nix · tailscale.nix · postgresql.nix · avahi.nix
│   ├── aggregations/         # the groups, one directory each
│   │   ├── default.nix       #   readDir, one level: `name = path`. imports no body
│   │   └── base/ desktop/ gaming/ hyprland/ shell/  # each default.nix is DATA,
│   │                                                #   beside an optional packages.nix
│   ├── overrides/            # capability-scoped fixes. empty is a real answer
│   │   └── default.nix       #   readDir, one level: every `*.nix` beside it is a record
│   └── dendrites/            # one file per capability, exposing the lanes it supports
│       ├── git.nix · btop.nix · yazi.nix …    #   { homeManager = …; }
│       ├── bluetooth.nix · syncthing.nix …    #   { nixos = …; }
│       ├── openai.nix                         #   { nixos = …; homeManager = …; }
│       ├── compositor/ gpu/                   #   a provider registry each
│       ├── desktop/ gaming/ hyprland/ server/ #   plain folders, nothing walks them
│       └── _shelved.nix      #   no catalogue line — parked, not deleted
├── templates/                # copyable example-*.nix, one per authoring role
├── tests/selection/          # the constructor's executable schema
├── tests/templates/          # proves templates/ still assembles into a real tree
├── tests/session-guard/      # a nested Hyprland must not walk off with the desktop
├── docs/HYPRLAND-SPLIT.md    # which file owns which old compositor block
├── pkgs/                     # custom derivations
├── secrets/                  # sops-encrypted
├── assets/                   # wallpapers, screenshots
└── scripts/                  # runtime shell scripts (keybinds, sink switcher)
```

> **The nucleus.** _At the heart of every flake sits a thing that cannot be removed — like my love of tomatoes._ `modules/nucleus/` is that floor beneath every machine: the system, the network, the secrets that keep the night out, the developer's claws— er, _tools._ You do not _choose_ the nucleus. It wears no flag, and so it simply _is_ — on every machine, always. Eat your tomatoes, Chiyo. Nyan. (=^･ω･^=)

`nucleus/` is the floor every host gets unconditionally — boot, network, ssh, secrets, dev tools. It is not in the catalogue and declares no toggle, so it always applies. Ungated *is* what makes it the nucleus. The account is not floor: it lives in `users/khoa.nix`, one shared definition a host *attaches* (`users.khoa.definition = ../../users/khoa.nix`), carrying `users.users.<name>` in its `nixos` lane and the home floor in its `homeManager` lane. There are no per-host copies.

> **The dendrites.** _From the frozen center, the arms reach outward — at Mach 100._ Each is one idea only — `bluetooth.nix`, `git.nix`, `waybar.nix` — _purr._ An arm that touched every machine would smother them all, so each one **sleeps** until it is named. Lean close, whiskers and all — an arm may have two paws, one for the **system** and one for the **home**, and each paw is called by name. Neither drags the other along. A dendrite never asks _"which machine am I for?"_ It waits to be selected. This is the way. Nyaa. (=ↀωↀ=)✧

A dendrite is one capability, one file, exposing the lanes it supports: `{ nixos = …; }`, `{ homeManager = …; }`, or both. Selecting it for the system imports its `nixos` lane; selecting it under a user imports its `homeManager` lane. Neither installs the other, and asking for a lane a dendrite does not expose is an error that names the dendrite, the scope, and the lanes it does have. A capability with several implementations is a directory whose `default.nix` lists `providers = { … }` and imports none of them — `gpu` is the worked example, and the unchosen `amd.nix`/`intel.nix` is never read. `compositor` is the same shape with one provider so far, `hyprland`; adding a second is a file beside it and a line in that registry, and nothing else moves.

`stylix` is the one capability every host selects whether or not it paints: Aoide's facets probe `options ? stylix` to decide whether to skip colour derivation, so the option tree must exist everywhere while `dx.stylix.enable` alone decides whether dxflake's own theme applies.

> **The aggregations.** _Sometimes many arms must wake as one — the way the government pays me to deliver presents to all the children in Japan, in a single night._ `base`, `desktop`, `shell`, `gaming` each keep one small house of their own under `modules/aggregations/`, and the **name on the door is the word** — inside there is no spell at all, only its list for the **machine** and its list for the **person**. Say the word over a machine and its system arms wake; say the same word over a person and that person's home arms wake. One word, two halves, one place to look. …Purr-fect, is it not. Nyan! ≽^•⩊•^≼

An aggregation is shared membership plus the preferences that belong with it, and it owns one directory: `modules/aggregations/desktop/default.nix`. That file is **data** — a `description`, a `system` half and a `home` half, each naming its `members` by catalogue name, the `providers` it lets a host choose, and an optional deferred `nixos`/`homeManager` block for a preference that rides along. It declares no options, carries no `mkIf`, and never sees a `scope` argument; the constructor wraps it in the gate, once, in the only place a gate exists. Either half may be absent — `gaming` has no home half, and that absence is a real answer, not an empty placeholder.

`aggregation.desktop.enable = true` on a host selects desktop's *system* members; `users.khoa.aggregation.desktop.enable = true` selects its *home* members for that person. `modules/aggregations/default.nix` is one `readDir` one level deep: every immediate child directory holding a `default.nix` is an aggregation, named by its directory, and it produces `name = path` without importing a body.

Provider choices nest under the aggregation that owns the dendrite. Every key in a half's `providers` becomes a `<name>.provider` option on that aggregation's own interface, in that scope:

```nix
aggregation.shell = {
  enable = true;
  compositor.provider = "hyprland";
};
```

`null` in the body means the group has no default and every host that selects it must choose, by name, or be told so; a string is a shared default a host may override. Those names are existing dendrites, not a new capability layer — a single-implementation member gets no provider option at all. The top-level `dendrites.<name>.provider` escape hatch still exists and still outranks the aggregation; an ordinary choice no longer needs it.

Membership and provider are both `mkDefault`, so a host's own `enable = false` beats them, two aggregations naming the same dendrite **merge** into one selection instead of instantiating it twice, and two that choose different providers for it collide with `has conflicting definition values`, naming the option and both values. Import order never decides.

Every `default.nix` under `modules/dendrites/` is therefore one thing now: an implementation the catalogue names, or a provider registry that lists paths and imports none. Groups live in their own tree, so the old two-kinds-of-`default.nix` ambiguity is gone.

> **The hosts.** _And so a machine is no longer a long and tiresome confession — only a handful of wishes spoken aloud._ A host names its hardware, then *wishes* — the aggregations and lone arms it wants, for the machine and for the person sitting at it. `sakaki` wishes only `base`, and purrs softly. `osaka` wishes desktop, shell, gaming — and does not tire. Read the wishes, and you will know the machine's dreams. ﻌ ฅ(=・ﻌ・=)ฅ

A host file is a *selection* — `aggregation`, `dendrites`, `users` — followed by its own `nixos` block: hardware imports, the `dx.*` knobs for what genuinely varies, host-only overlays and packages. A host names no module file, and neither does an aggregation — its members are catalogue names. Only the catalogue and a provider registry ever name a path.

Chiyo enables its SSH tunnel through `dx.cloudflared`. This flake provides no CSC (FAU) manual tunnel token module or `dx.cscToken` option.

> _To give a thing to every machine, drop it in the **nucleus** and give it no flag. To give it to only some, write its name in the **catalogue** and let a machine — or a person — select it. To take a thing away entirely, strike its catalogue line; the file may go on sleeping on disk. Never again ask a meow-dule who it belongs to._ …That is all. I must go now — I can fly, you know. At Mach 100. Nyaaa~ =^ｪ^= ⌒☆ 🐾💨

**The three moving parts, plainly:**

- **Catalogue** — `modules/default.nix`, one `name = ./path;` line per capability. It generates `dendrites.<name>.enable` and `.provider`, so an unknown name fails as an option that does not exist, naming the file that asked for it. A capability with no catalogue line is unreachable — that is what shelving means now. The file is not a module: it is plain data, `{ catalogue = { … }; aggregations = import ./aggregations; overrides = import ./overrides; }`, and `flake.nix` hands it to the constructor as `registry` alongside `hostModules = [ ./hosts/<name> ]`.
- **Aggregations** — `modules/aggregations/<group>/default.nix`, found by directory name one level deep. Dendrites are written down by hand because an implementation must never become reachable by dropping a file somewhere; an aggregation body is inert data whose only effect is the gate it answers, so its directory name is enough.
- **Selection** — resolved *before* any platform module graph exists, because `mkDefault` sets definition priority and cannot decide imports, and `mkIf` cannot keep an imported module's declarations out of the graph that imported them. Pass one is an ordinary `lib.evalModules` over enable/provider options; pass two imports only what it resolved, so an unselected file is never read. A `dx.*` option still gates the knobs that genuinely vary (`caddy.sites`, `nas-mounts.mounts`, …), never whether the file is reached at all.

Pass one runs in two steps, because the nested provider option names come out of the bodies themselves:

```text
modules/aggregations/default.nix   names directories, imports no body
       ↓
gate     every aggregation declares only `enable`; the rest of its attrset is
         freeform and ignored. Which did this host, or one of its users, select?
       ↓
select   import THOSE bodies — the union of both scopes. They declare their real
         nested provider options and write their membership. No other body is read.
       ↓
platform import the chosen dendrite files and the chosen provider files.
         Nothing else under modules/dendrites/ is read at all.
```

A body is data, so it cannot enable another aggregation: the gate step's answer is the select step's answer, and no recursion machinery exists to say so. A body one of the users selected is present in the host scope too, gated off — the union is imported, not a separate list per scope.

Override records are the one documented exception to all of that, and the weaker boundary is stated rather than glossed. A record under `modules/overrides/` is a fix that belongs to a capability instead of to a host — a package upstream broke, a setting everyone running the thing needs. It names its targets by catalogue name, optionally confines itself to named hosts, and carries an `overlay`, a `nixos` module, a `homeManager` module, or any combination. Every host **imports every record file**, because matching means reading which dendrites a record targets; what an unmatched host never spends is the *work*, since those three are functions and nothing calls them. A record never selects anything, applies at most once however many of its targets were hit, and takes its order from the record name. This tree ships no live record — `modules/overrides/` holds only its discovery file.

To shelve a capability without deleting it, strike its catalogue line; the file conventionally keeps its `_`-prefixed name, e.g. `_foo.nix`, as a visual marker.

---

## Not the *pure* dendritic pattern

This flake *is* dendritic — one file per capability, each carrying its own lanes, and the import list is written rather than discovered: `modules/default.nix` names exactly the capabilities that exist, one line each. Group *names* are the one thing read off disk, and a name found that way imports nothing until a host says it. That is the dendritic essence, and this flake has it, on an **explicit catalogue plus selection** rather than automatic enumeration. What it is **not** is the [*pure* dendritic pattern](https://github.com/mightyiam/dendritic) ([FAQ](https://github.com/Doc-Steve/dendritic-design-with-flake-parts/wiki/FAQ#dendritic-pattern-seems-just-like-a-buzzword-why-is-this-different-from-what-im-already-doing-for-the-configuration-of-my-hosts)): it stops one pillar short. Where they part is the foundation:

| | this flake (catalogue + selection) | dendritic pattern |
|---|---|---|
| Foundation | `nixpkgs.lib.nixosSystem`, behind a selection-then-platform constructor | `flake-parts` |
| Discovery | an explicit catalogue, one line per capability, in `modules/default.nix`; group *names* from one `readDir`, one level deep, importing nothing | `import-tree`, the whole tree, recursively |
| Auto-wiring **scope** | feeds `nixosConfigurations` **only** | one file registers into every output — `nixos` + `homeManager` + `perSystem` packages, devShells |
| Scoping to a host | selection, resolved before any import | options / selection |
| System + home | one dendrite exposes a `nixos` lane, a `homeManager` lane, or both; each is selected on its own | one file registers into both module classes |

The difference is **pillar 2.** This flake takes pillar 1's shape — the import list is data, not a directory walk — by hand, one catalogue line per capability, with no new dependency (`lib.filesystem.listFilesRecursive` still ships in nixpkgs; this flake calls it nowhere — even the upstream Aoide songs are named one by one in `flake.nix`). The one filesystem read left is `builtins.readDir` in `modules/aggregations/default.nix`, one level deep over directory names, and it imports nothing: `import-tree` enumerates files *into* the module graph, while a name found here is inert until a host selects it, and no implementation is ever reachable by dropping a file in a directory. Pillar 2 is `flake-parts`: a single file registering into *many* flake outputs at once (packages, devShells, multi-arch `perSystem`, whole configs). Taking it means a paradigm change (`nixosSystem → flake-parts`) plus `import-tree`, and it only pays off across outputs a single-target NixOS config doesn't ship. The "one dendrite reaches system + home" here works because the constructor hands each lane to the evaluator that asked for it and Home Manager rides the NixOS module, not because a multi-output module system sits underneath.

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

3. Write `hosts/<name>/default.nix` — a selection, then this host's own settings. The account comes from `users/khoa.nix`; you attach it, you do not copy it. `templates/example-host.nix` is this file with the comments left in:

   ```nix
   {
     aggregation = {
       base.enable = true;        # the machine's half: stylix
       desktop.enable = true;     # audio, fonts, portals, login …
       shell = {
         enable = true;           # the compositor and the surfaces on it
         compositor.provider = "hyprland";
       };
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
         shell.enable = true;     # waybar, rofi, wlogout, satty
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
- `modules/dendrites/compositor/hyprland.nix` derives active/inactive borders
  from the resolved livery under AOIDE ownership, otherwise keeps historical
  RGBA.

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

`templates/` holds one copyable `example-*.nix` per authoring role — dendrite, provider registry, provider, aggregation, host, user, nucleus file, package — with a table in `templates/README.md` saying where each copy goes and what the one follow-up line is. `./tests/templates/run.sh` assembles a whole tree out of that directory and resolves it against the real constructor, so the examples stay true.

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

Then `gpu = { enable = true; provider = "amd"; }` on the host — `intel.nix` is never read. A provider-bearing member of an aggregation is chosen on that aggregation instead: `aggregation.shell.compositor.provider = "hyprland"`.

An **aggregation** is a directory under `modules/aggregations/`, and its `default.nix` is data — no options, no `mkIf`, no `scope`:

```nix
# modules/aggregations/shell/default.nix
{
  description = "The desktop shell: the compositor and the surfaces drawn on it.";

  system = {
    providers.compositor = null;     # no default: every host that takes this must choose
    nixos.imports = [ ./packages.nix ];   # what this aggregation installs; not a dendrite
  };

  home.members = [ "rofi" "satty" "waybar" "wlogout" ];
}
```

Discovery finds it by directory name; nothing imports it until a host or a user selects it. Members are catalogue names, so they stay where they live under `modules/dendrites/` rather than moving under the group. Each `providers` key becomes a `<name>.provider` option on this aggregation, in that scope — `null` demands a choice, a string is a default a host may override. A half that does not apply is left out; `gaming` has no `home` at all.

What an aggregation **installs** goes in its own `nixos`/`homeManager` block, not in a member: a package list answers no question a host could answer differently, so there is nothing to select and it gets no catalogue line. Long lists live in a `packages.nix` beside the `default.nix` that imports it — `desktop/` and `shell/` have one; `gaming` says its nine launchers inline, which is the same thing at a size that does not need a file.

**Two kinds of module, by what they need from a host:**
- **Selected = active** — no `options.dx.<name>.enable` at all; the lane applies the moment it is selected, and dropping the selection is how a host opts out. (`bluetooth.nix`, `aoide.nix`, and every capability with no knobs of its own)
- **`dx.` knobs for what genuinely varies** — a capability some hosts configure differently keeps `options.dx.<name>.<knob>` for that variance only, never for whether it runs (`caddy.sites`, `cloudflared.tunnelId`/`hostnames`, `immich.mediaLocation`, `inference.igpu`, `nas-mounts.server`/`mounts`).

Aggregations follow the same rule one level up: a group names each member once, in the half that matches the lane it rides, and a host or a user says the word. A shared preference that belongs to the whole group rides that half's deferred `nixos`/`homeManager` block, never a repeat across hosts.

**What you never touch:** `flake.nix`, or any module path outside `modules/default.nix` and the provider registry of the capability you are adding to — those are the only places a file is named. Need a new aggregation? Add a directory under `modules/aggregations/` with a `default.nix` holding its `description` and its halves; there is no import line to add, because discovery names it and the constructor supplies the gate. Want to park a capability without deleting it? Strike its catalogue line.

An **override record** is the last shape, and the one to reach for only when a fix belongs to a capability rather than to a host — a package upstream broke, a setting every machine running the thing needs. Drop a file under `modules/overrides/`:

```nix
# modules/overrides/browser.nix
{
  dendrites = [ "browser" ];        # catalogue names — required
  hosts = [ "osaka" "sakaki" ];     # optional; omit for every host that selected one
  overlay = _final: prev: { … };    # host package set
  nixos = { lib, ... }: { … };      # deferred platform module
  homeManager = { … };              # rides only the users who selected a target
}
```

Discovery finds it; there is no catalogue line and no collector. A record never *selects* anything — targeting a capability nobody chose is a record that does not apply. Repeating the fix in each host drifts, putting it in the dendrite confuses what the thing IS with a patch log, and a new aggregation or provider turns a patch into a capability: none of those. Unknown fields, unknown targets and unknown host names fail on **every** host, naming the record, so a broken one cannot hide on the machines it would not have applied to.

**Prove it still holds:**

```sh
nix eval --json .#inventory.<host> | jq   # what this host resolved, and from where
./tests/selection/run.sh                  # the constructor's executable schema
./tests/templates/run.sh                  # templates/ still assembles into a real tree
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
- a nested Hyprland that cannot steal your session out from under you
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
