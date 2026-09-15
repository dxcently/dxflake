# The Hyprland split — what moved where

`modules/dendrites/compositor/hyprland.nix` was 543 lines carrying five
unrelated jobs. This is the map from those blocks to the files that own them
now. Read it once; after that the file headers are the reference.

## The rule the split follows

**The compositor provider is what makes Hyprland *run*.** Session, monitors,
environment, the systemd handoff. A host that selects it gets a working,
navigable Hyprland and nothing opinionated.

**Everything else is ecosystem** and is selected by name. What is written
against Hyprland itself lives under `modules/dendrites/hyprland/`; the
compositor-agnostic surfaces sit at the dendrite root. Each one is independently selectable because each
answers a question a host can answer differently — chiyo answers all of them
with Aoide's facets instead, selects neither `shell` nor `compositor`, and
imports the single dendrite (`hyprlock`) it still wants.

## Old block → new owner

| old block (`compositor/hyprland.nix`)            | lines   | owner now                           |
| ------------------------------------------------ | ------- | ----------------------------------- |
| `programs.hyprland` (enable, withUWSM)            | 56-59   | `compositor/hyprland.nix`           |
| `home.sessionVariables.NIXOS_OZONE_WL`            | 81      | `compositor/hyprland.nix`           |
| `hyprland.{enable,systemd.enable,xwayland}`       | 85-104  | `compositor/hyprland.nix`           |
| session handoff + `hyprland-session.target`       | 70-72, 161-163, 184, 512-537 | `compositor/hyprland.nix` |
| `monitor`                                         | 134-141 | `compositor/hyprland.nix`           |
| `env`                                             | 143-148 | `compositor/hyprland.nix`           |
| `exec-once` (user programs)                       | 164-183 | `hyprland/autostart.nix`            |
| `hyprpolkitagent` package                         | 77      | `hyprland/autostart.nix`            |
| `settings.extraConfig` windowrules 1-6            | 186-233 | `hyprland/keybinds.nix`             |
| `workspace`                                       | 235-262 | `hyprland/keybinds.nix`             |
| `bind`, `bindm`                                   | 264-344 | `hyprland/keybinds.nix`             |
| `input`                                           | 346-358 | `hyprland/keybinds.nix`             |
| `hyprshot`, `hyprpicker` packages                 | 78-79   | `hyprland/keybinds.nix`             |
| `general` (incl. livery borders)                  | 360-368 | `hyprland/decoration.nix`           |
| `decoration`                                      | 370-387 | `hyprland/decoration.nix`           |
| `layerrule` (waybar)                              | 398-400 | `hyprland/decoration.nix`           |
| `animations`                                      | 412-423 | `hyprland/decoration.nix`           |
| `dwindle`/`master`/`scrolling`/`misc`/`ecosystem` | 425-447 | `hyprland/decoration.nix`           |
| `plugins = [ hyprglass ]` + the ABI note          | 106-122 | `hyprland/hyprglass.nix`            |
| `layerrule` (aoide-*)                             | 401-410 | `hyprland/hyprglass.nix`            |
| `plugin:hyprglass { … }` config                   | 450-473 | `hyprland/hyprglass.nix`            |
| kitty aero-glass windowrules                      | 486-510 | `hyprland/hyprglass.nix`            |

## Independently selectable, vs. private helper

Selectable — each has a catalogue line, can be named on its own, and is named
by exactly one aggregation:

| name                   | path                                 | lane        | named by     |
| ---------------------- | ------------------------------------ | ----------- | ------------ |
| `compositor`           | `dendrites/compositor` (provider)    | nixos       | `shell`      |
| `rofi` `satty` `waybar` `wlogout` | `dendrites/<name>.nix`         | homeManager | `shell`      |
| `hyprland-autostart`   | `dendrites/hyprland/autostart.nix`   | homeManager | `compositor` |
| `hyprland-decoration`  | `dendrites/hyprland/decoration.nix`  | homeManager | `compositor` |
| `hyprland-keybinds`    | `dendrites/hyprland/keybinds.nix`    | homeManager | `compositor` |
| `hyprglass`            | `dendrites/hyprland/hyprglass.nix`   | homeManager | `compositor` |

Private helpers — no catalogue line, reachable only from the file that imports
them by relative path:

| path                                          | imported by                        |
| --------------------------------------------- | ---------------------------------- |
| `dendrites/compositor/session-import.nix`      | `compositor/hyprland.nix`          |
| `dendrites/compositor/hypr-session-import.sh`  | `compositor/session-import.nix`    |

**The folder agrees with the membership, and only there.** The dendrite root is
flat: one file per single-implementation capability, and grouping is the
aggregations' job, never a directory's. A directory under `dendrites/` means
one of two things. `compositor/`, `gpu/` and `fastfetch/` are capabilities that
need several files — the first two carry a `default.nix` provider registry and
import only the chosen provider. `hyprland/` is the one grouping folder kept,
and it earns that by holding exactly what is written or compiled against
Hyprland: the four members the `compositor` aggregation names, and nothing
else. It has no `default.nix`, nothing walks it, and every file in it is
reachable only through its own catalogue line. The surfaces (`rofi`, `satty`,
`waybar`, `wlogout`) predate the split and are compositor-agnostic, which is
why they sit at the root and belong to `shell`. What a host gets is still
decided by the aggregation that names a dendrite, never by where it sits.

## Packages

The compositor implementation installs nothing. Two rules decide where a
package goes instead.

**A package whose only caller is one dendrite is that dendrite's dependency**,
not free-floating membership, so the three `hypr*` tools travel with the file
that invokes them: `hyprpolkitagent` → `hyprland-autostart` (it runs
`systemctl --user start` on it), `hyprshot` + `hyprpicker` →
`hyprland-keybinds` (its binds shell out to both). Both dendrites are the
`compositor` aggregation's, so a host on another compositor installs neither.

**A package nothing in particular calls is the aggregation's own install**, and
an install is not a capability — it answers no question a host could answer
differently, so it gets no catalogue line. The Wayland tool belt (dunst, awww,
wl-clipboard, satty, cliphist, brightnessctl, ydotool, yad, zenity) is now
`modules/aggregations/shell/packages.nix`, imported by that aggregation's
`system.nixos` and by nothing else. There is no `hyprland-packages` dendrite any
more — nor `desktop-packages` or `gaming-packages`, which moved the same way.
Nothing in the tool belt is Hyprland-specific, so it stays with the
compositor-agnostic half.

Those lists are `lib.mkAfter`. `system.path` resolves file collisions
first-wins, and without a pin an aggregation's list sits wherever module order
happens to put it; ordering it last means a convenience package can never
shadow a capability a host actually selected.

Package *builds* did not move: `pkgs/` is untouched, and `pkgs.hyprglass`
still comes from the Aoide input's overlay.

**One duplicate removed.** `waybar` was installed twice — once by the tool belt
into `environment.systemPackages`, and again by
`programs.waybar.enable` into `home.packages`. The systemPackages copy is gone;
the module option's copy is the one that was always carrying the config.

## Not evaluating Hyprland on a non-Hyprland host

`pkgs.hyprglass` is a plugin compiled against one compositor commit, so it must
never be evaluated on a host that picked a different compositor.

Aggregation membership is **static** — `members` is data read before any
provider answer is known — so a Hyprland-only dendrite parked in `shell` would
still be evaluated by a host that answered `compositor.provider` with something
else. Putting it in a *sibling aggregation* is what actually gates it, because
selection happens one level up:

1. the provider registry imports only the chosen implementation, and
2. every Hyprland-only dendrite is named by `modules/aggregations/compositor/`,
   which a non-Hyprland host simply does not select.

`tests/selection` proves both against `tests/selection/aggregations/backend/`,
whose only member throws on import:

| case                            | asserts                                                     |
| ------------------------------- | ----------------------------------------------------------- |
| `backendAggregationIsInert`     | selecting the provider-bearing sibling and forcing the whole resolution never reaches the landmine |
| `backendAggregationIsReachable` | the landmine is real — selecting `backend` does throw        |

The second case is what keeps the first honest: without it, a fixture that had
quietly stopped being imported at all would still pass.

## Generated-config fix that came with the move

The windowrules used to live in `settings.extraConfig`, and `settings` renders
`key=value` — so every generated `hyprland.conf` carried a literal, bogus
`extraConfig=` keyword line ahead of them. They now sit in the **top-level**
`extraConfig` (`types.lines`, emitted raw at the end of the file), byte for
byte otherwise. The stray keyword is gone.
