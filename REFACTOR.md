# sakaki config refactor

## Overview

Refactor the NixOS flake from a monolithic `default.nix`-per-layer model
to explicit host-driven composition. Each host's `default.nix` becomes the
single, complete list of everything that machine runs — both system and
home-manager modules. Modules are plain config files with no conditionals.

Adding a new host = one line in `flake.nix` + a new `hosts/<name>/default.nix`.
Adding a module to N hosts = create the file, add it to N import lists.

Branch: `claude/sakaki-config-refactor-8j9bv6`

---

## Before / After

### Before

```
flake.nix
  → hosts/chiyo        → modules/core/default.nix   (imports everything)
  → hosts/osaka        → modules/core/default.nix
                         modules/core/default.osaka.nix  (osaka extras)
                         user.nix (if host == "osaka" home branch)
  → no sakaki
```

### After

```
flake.nix  (mkHost helper — one line per host)
  → hosts/chiyo/default.nix   (explicit full import list, system + home)
  → hosts/osaka/default.nix   (explicit full import list, system + home)
  → hosts/sakaki/default.nix  (new server — explicit minimal list)
```

---

## Design principles

- **Host file = source of truth.** Read one file, know everything a machine runs.
- **Modules are pure.** No `mkIf`, no `host ==` checks, no enable options.
- **Modules own their flake deps.** `stylix.nix` imports the stylix nixosModule itself. Same for sops-nix, aagl.
- **No profiles, no wrappers.** Repetition in host files is acceptable and honest.
- **`flake.nix` is just a registry.** `mkHost` reduces per-host boilerplate to one line.

---

## Agent delegation

Spawn **4 agents in parallel** — they touch disjoint files.

| Agent | Scope | Files touched |
|---|---|---|
| A | Core module changes | `modules/core/user.nix`, `stylix.nix`, `hermes.nix`, `aagl.nix`, `services.nix` + new `desktop-services.nix` |
| B | Rewrite existing hosts | `hosts/chiyo/default.nix`, `hosts/osaka/default.nix` |
| C | Create sakaki | `hosts/sakaki/default.nix`, `hosts/sakaki/hardware.nix` |
| D | Flake + cleanup | `flake.nix`, delete 4 old `default.nix` files |

After all 4 complete, run a single commit and push.

---

## Tasks

### Agent A — Core module changes

Read each file before editing.

- [ ] **`modules/core/user.nix`**
  - Keep: `imports = [inputs.home-manager.nixosModules.home-manager]`
  - Keep: `home-manager` block with `useUserPackages`, `useGlobalPkgs`,
    `extraSpecialArgs = { inherit inputs username host; }`,
    `backupFileExtension`, `home.username`, `home.homeDirectory`,
    `home.stateVersion`, `programs.home-manager.enable`
  - Keep: `users.users.${username}` block and `nix.settings.allowed-users`
  - **Remove:** entire `users.${username}.imports = if (host == "osaka") ...` block
  - Hosts will set `home-manager.users.${username}.imports` themselves

- [ ] **`modules/core/stylix.nix`**
  - Add `imports = [ inputs.stylix.nixosModules.stylix ];` as the first line
    inside the module body (needs `inputs` in function args)

- [ ] **`modules/core/hermes.nix`**
  - Add `imports = [ inputs.sops-nix.nixosModules.sops ];` as the first line
    inside the module body (needs `inputs` in function args)

- [ ] **`modules/core/aagl.nix`**
  - Add `imports = [ inputs.aagl.nixosModules.default ];` as the first line
    inside the module body (needs `inputs` in function args)

- [ ] **`modules/core/services.nix`** — split into two files
  - **Keep in `services.nix`:** `hydra`, `openssh`, `avahi`, `postgresql`, `tailscale`
  - **Move to new `modules/core/desktop-services.nix`:**
    `devmon`, `blueman`, `gvfs`, `udisks2`, `flatpak`, `printing`
  - `desktop-services.nix` uses the same `{ pkgs, config, ... }:` signature

---

### Agent B — Rewrite existing hosts

Read each file before rewriting. Preserve all host-specific config
(boot, hardware, GPU drivers, packages, services overrides). Only replace
the `imports` block and add the `home-manager.users.${username}.imports`
block.

- [ ] **`hosts/chiyo/default.nix`**

  Add `username` to function args: `{ inputs, lib, config, pkgs, username, ... }:`

  Replace imports block with:
  ```nix
  imports = [
    ./hardware.nix
    ../../modules/core/system.nix
    ../../modules/core/networking.nix
    ../../modules/core/security.nix
    ../../modules/core/packages.nix
    ../../modules/core/user.nix
    ../../modules/core/displaymanager.nix
    ../../modules/core/fonts.nix
    ../../modules/core/hardware.nix
    ../../modules/core/pipewire.nix
    ../../modules/core/fcitx5.nix
    ../../modules/core/stylix.nix
    ../../modules/core/xserver.nix
    ../../modules/core/thunar.nix
    ../../modules/core/services.nix
    ../../modules/core/desktop-services.nix
    ../../modules/core/syncthing.nix
    ../../modules/core/hermes.nix
  ];
  ```

  Add after imports (top level, alongside existing host config):
  ```nix
  home-manager.users.${username}.imports = [
    ../../modules/home/bash.nix
    ../../modules/home/git.nix
    ../../modules/home/neovim.nix
    ../../modules/home/yazi.nix
    ../../modules/home/btop.nix
    ../../modules/home/nh.nix
    ../../modules/home/composekey.nix
    ../../modules/home/hyprland.nix
    ../../modules/home/waybar.nix
    ../../modules/home/kitty.nix
    ../../modules/home/rofi.nix
    ../../modules/home/stylix.nix
    ../../modules/home/gtk.nix
    ../../modules/home/qt.nix
    ../../modules/home/hyprlock.nix
    ../../modules/home/hyprpaper.nix
    ../../modules/home/wlogout.nix
    ../../modules/home/librewolf.nix
    ../../modules/home/vesktop.nix
    ../../modules/home/floorp.nix
    ../../modules/home/swappy.nix
    ../../modules/home/virtmanager.nix
    ../../modules/home/fastfetch/fastfetch.nix
  ];
  ```

- [ ] **`hosts/osaka/default.nix`**

  Add `username` to function args: `{ inputs, lib, config, pkgs, username, ... }:`

  Replace imports block with:
  ```nix
  imports = [
    ./hardware.nix
    ../../modules/core/system.nix
    ../../modules/core/networking.nix
    ../../modules/core/security.nix
    ../../modules/core/packages.nix
    ../../modules/core/user.nix
    ../../modules/core/displaymanager.nix
    ../../modules/core/fonts.nix
    ../../modules/core/hardware.nix
    ../../modules/core/pipewire.nix
    ../../modules/core/fcitx5.nix
    ../../modules/core/stylix.nix
    ../../modules/core/xserver.nix
    ../../modules/core/thunar.nix
    ../../modules/core/steam.nix
    ../../modules/core/aagl.nix
    ../../modules/core/virtualisation.nix
    ../../modules/core/services.nix
    ../../modules/core/desktop-services.nix
    ../../modules/core/syncthing.nix
    ../../modules/core/hermes.nix
    ../../modules/core/jellyfin.nix
  ];
  ```

  Remove: `../../modules/core/default.osaka.nix` (was in old imports, already deleted by Agent D)

  Add after imports:
  ```nix
  home-manager.users.${username}.imports = [
    ../../modules/home/bash.nix
    ../../modules/home/git.nix
    ../../modules/home/neovim.nix
    ../../modules/home/yazi.nix
    ../../modules/home/btop.nix
    ../../modules/home/nh.nix
    ../../modules/home/composekey.nix
    ../../modules/home/hyprland.nix
    ../../modules/home/waybar.nix
    ../../modules/home/kitty.nix
    ../../modules/home/rofi.nix
    ../../modules/home/stylix.nix
    ../../modules/home/gtk.nix
    ../../modules/home/qt.nix
    ../../modules/home/hyprlock.nix
    ../../modules/home/hyprpaper.nix
    ../../modules/home/wlogout.nix
    ../../modules/home/librewolf.nix
    ../../modules/home/vesktop.nix
    ../../modules/home/floorp.nix
    ../../modules/home/swappy.nix
    ../../modules/home/virtmanager.nix
    ../../modules/home/fastfetch/fastfetch.nix
  ];
  ```

---

### Agent C — Create sakaki

- [ ] **`hosts/sakaki/hardware.nix`** — create placeholder:
  ```nix
  { ... }: {
    # TODO: sakaki hardware configuration
  }
  ```

- [ ] **`hosts/sakaki/default.nix`** — create minimal server skeleton:
  ```nix
  { inputs, lib, config, pkgs, username, ... }: {
    imports = [
      ./hardware.nix
      ../../modules/core/system.nix
      ../../modules/core/networking.nix
      ../../modules/core/packages.nix
      ../../modules/core/user.nix
      ../../modules/core/services.nix
      ../../modules/core/jellyfin.nix
    ];

    home-manager.users.${username}.imports = [
      ../../modules/home/bash.nix
      ../../modules/home/git.nix
      ../../modules/home/neovim.nix
      ../../modules/home/yazi.nix
      ../../modules/home/btop.nix
      ../../modules/home/nh.nix
    ];

    networking.hostName = "sakaki";

    boot = {
      loader.systemd-boot.enable = true;
      loader.efi.canTouchEfiVariables = true;
    };
  }
  ```

---

### Agent D — Flake + cleanup

- [ ] **Delete** `modules/core/default.nix`
- [ ] **Delete** `modules/core/default.osaka.nix`
- [ ] **Delete** `modules/home/default.nix`
- [ ] **Delete** `modules/home/default.osaka.nix`

- [ ] **Rewrite `flake.nix`** — replace the outputs block with a `mkHost` helper.
  Preserve all inputs exactly as-is. Only the `outputs` block changes:

  ```nix
  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    home-manager,
    ...
  } @ inputs: let
    system   = "x86_64-linux";
    username = "khoa";
    mkHost   = name: nixpkgs.lib.nixosSystem {
      specialArgs = {
        host = name;
        inherit username inputs system nixpkgs-stable;
      };
      modules = [ ./hosts/${name} ];
    };
  in {
    nixosConfigurations = {
      chiyo  = mkHost "chiyo";
      osaka  = mkHost "osaka";
      sakaki = mkHost "sakaki";
    };
  };
  ```

---

## Commit

After all agents complete, from the repo root:

```
git commit -am "refactor: explicit host composition, add sakaki skeleton"
git push -u origin claude/sakaki-config-refactor-8j9bv6
```

---

## Validation checklist

- [ ] `modules/core/default.nix` does not exist
- [ ] `modules/core/default.osaka.nix` does not exist
- [ ] `modules/home/default.nix` does not exist
- [ ] `modules/home/default.osaka.nix` does not exist
- [ ] `modules/core/user.nix` has no `if host ==` conditional
- [ ] `modules/core/desktop-services.nix` exists with blueman/flatpak/printing/devmon/gvfs/udisks2
- [ ] `modules/core/services.nix` has only openssh/avahi/tailscale/postgresql/hydra
- [ ] `modules/core/stylix.nix` imports `inputs.stylix.nixosModules.stylix`
- [ ] `modules/core/hermes.nix` imports `inputs.sops-nix.nixosModules.sops`
- [ ] `modules/core/aagl.nix` imports `inputs.aagl.nixosModules.default`
- [ ] `hosts/chiyo/default.nix` has explicit imports list and `home-manager.users.${username}.imports`
- [ ] `hosts/osaka/default.nix` has explicit imports list and `home-manager.users.${username}.imports`
- [ ] `hosts/sakaki/default.nix` exists
- [ ] `hosts/sakaki/hardware.nix` exists
- [ ] `flake.nix` uses `mkHost` helper; adding a host is one line
