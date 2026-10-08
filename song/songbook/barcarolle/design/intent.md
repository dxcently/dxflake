# barcarolle — intent

Windows 7 Aero, rebuilt as an AoideOS rice: a glass superbar along the bottom,
the Start orb and its two-column menu, white-plate flyouts and balloons, a
Vista-lineage sidebar, and a CPU-meter gadget, all over a teal Frutiger Aero
wallpaper. The one structural change from Windows 7: the grouped taskbar
buttons are **Hyprland workspaces**, not applications.

The board is `mock.html` (rendered to `mock.png`). It holds every summoned
surface open at once on one 1920×1080 output, which the real desktop never
does. It is a reference for the QML, not a spec of behaviour.

## Grammar

Glass is a frame, content is a plate, light comes from above.

- **Deep glass** (`bar.bg`) is the only glass that carries text, always white.
- **Colorization** (`window.border`) tints every frame — Start rim, flyout
  rims, peek frame, sidebar column, active window border — and never carries
  text.
- **Plates** (`notif.bg` at 0.97, 1px ink-0.55 border) carry every list,
  grid, paragraph and field; ink text on them.
- Colour on glass appears only as gloss pills and badges with ink labels,
  progress washes, and the `bar.accent` glow.
- Light: a 1px white top highlight, a hard-stop gloss over the top half,
  faint diagonal streaks.

## Layout (DP-1, 1920×1080)

```
┌───────────────────────────────────────────────────────────────┬──────────────┐
│                                           [CPU/RAM gadget]    │ Sidebar      │
│                                                               │  Sessions    │
│                                                               │  by workspace│
│ ┌Start──────────┐                                             │  + New term  │
│ │ pinned │ name  │      ┌Peek ws7┐            ┌RICE menu┐ ┌balloon────────┐ │
│ │ recent │ places│      │ rows   │            │ songs   │ │ approve/deny  │ │
│ │ All ▸  │       │      └────────┘            │ drafts  │ └──────┬────────┘ │
│ │ search │ Lock ▸│                            │         │  ┊  ┌vol┐         │
├─┴───────┴───────┴──────────────────────────────────────────────────────────────┤
│◉ [1][2][3][4][5][6][7][8] ┆ mag scr +              Stage▾ ^ ⧉ ⚑ ▭ ◁)) 3:42 ▐│
└────────────────────────────────────────────────────────────────────────────────┘
```

- **Superbar**, 40px, bottom. Orb (0–54) · workspace strip from 58 · groove ·
  special drawers · always-visible `+` · notification area: RICE cell,
  chevron overflow, agents, Action Center flag, network, volume · two-line
  clock · 15px show-desktop sliver.
- **Workspace button**, 62×40: 28px front icon (focused or most-windowed
  class), up to two 14px minis beside it, number chip bottom-left, agent
  badge, stack edges for 2+/3+ windows. Empty workspaces are 40px ghosts.
  Washes follow Win7 taskbar progress: working green, awaiting yellow, urgent
  orange (the vesktop button on 6).
- **Aero Peek**: hover a button → a rim + deep header + plate list of that
  workspace's windows; an agent's window carries its state dot and tool.
- **Start**: left plate of pinned (Terminal, Firefox) and recent programs
  with jump-list arrows, `All Programs ▸`, search field at the bottom
  ("Search programs and files"); right deep pane with the user tile
  protruding above the frame, the name, places, Terminal, Settings; the power
  split is **Lock** with a ▸ for Switch user / Log off / Sleep / Hibernate /
  Restart / Shut down.
- **Sidebar dock** (right, 352px, summoned): header chip with counts, one
  gadget card grouping sessions by workspace (mini workspace button + label;
  click jumps), rows with a state orb, agent · title, tool and cwd tail, and
  a context meter. Subagents indent. "Elsewhere" holds sessions with no
  window. `+ New terminal` at the foot.
- **RICE cell + menu**: the cell shows the mode glyph and word (`Stage`) with
  a chevron. The menu: header `Rice · <song> · <mode>`, songs with the
  current one ticked (staged / declared tags), `Back to declarative ·
  <declared>`, drafts of the current song, `+ New draft`, `Save current as
  draft`.
- **Tray flyout**: the Win7 narrow volume flyout (device, slider, percent,
  mute, `Mixer` footer).
- **Balloon**: white plate with a tail on the flag; a summons shows Approve /
  Deny pills.
- **Gadget**: CPU (110px) and RAM (70px) dials, chrome bezels, white needles,
  readouts on dark chips.
- **Lock** (panel in the board, 0.45 scale): the logon picture with its baked
  person tile, the `$USER` label at −21% and the 400×60 hyprlock field at
  −26% below centre. Nothing else; the song supplies only the picture and
  colours (hyprlock dress contract).

## Agent states

The canonical five from `sessions.json`: `working` (base0B green) ·
`awaiting` (base0A yellow, pause bars — the one that is *asking*) · `idle`
(base04 grey) · `stopped` (white orb with an ink stop square) · `done`
(accent with a check).

## Palette tokens used

| token | hex | role |
|---|---|---|
| bar.bg | `#0c2130` | deep glass, ink |
| bar.fg | `#ffffff` | text on glass |
| bar.accent | `#77fffc` | glow, hot-track, open-drawer edge |
| palette.accent / base0D | `#25bbcf` | selection, today, focused-row rule, volume fill |
| window.border | `#2aa3b8` | colorization: rims, frames, lock field outline |
| notif.bg / base07 | `#f5fbfb` | plates |
| notif.fg | `#0c2130` | ink on plates |
| base0B (hot) | `#3bdcac` | working, Approve |
| base0A | `#e8cf6a` | awaiting |
| base09 | `#f2a65e` | urgent wash, flag dot |
| urgent / base08 | `#f47a72` | Deny, needle tip |
| base04 / base03 | `#8db0ba` / `#6a8f9c` | idle, chrome |
| base0C / base0E | `#4fd8e6` / `#a99cf6` | orb flag band, person tile |

Font stack: Segoe UI → Selawik → Noto Sans → Open Sans → DejaVu Sans; mono
Consolas → Noto Sans Mono.

## Mocked vs real

- **Glass**: CSS `backdrop-filter` blur + a streak layer stands in for
  Hyprland blur and hyprglass refraction. The real strip is planned as a
  baked frost (no compositor rule); popups get `blur_popups`; Start and the
  dock get hyprglass.
- **Icons**: all drawn here, original; the real bar resolves app icons from
  the icon theme.
- **Data**: workspaces, sessions, songs and drafts are hard-coded sample
  data. Nothing reads `desktop.json`, `sessions.json` or `mode.json`.
- **Board-only placement**: every surface is open at once. The peek is
  shifted right to clear the open Start menu; the balloon is lifted above
  the open flyouts with a dashed leader down to the flag it belongs to; the
  gadget sits left of the open sidebar instead of under it.
- Not shown: the HDMI-A-1 compact bar, jump lists, chevron overflow grid,
  network and calendar flyouts, Action Center, power screen, window frames
  and terminals.

## Open questions

1. **Sidebar vs flyouts**: the dock is full height on the right, so every
   tray flyout and the balloon land on top of it. Hide the dock when a tray
   flyout opens (current spec), or end the dock above the tray area?
2. **Gadget home**: desktop at top-right (collides with the open dock), or
   docked into the sidebar column like Vista when the sidebar is shown?
3. **"awaiting" vs "asking"**: display the canonical word, or map it to
   "asking" in the UI only?
4. **Start search**: the placeholder says "programs and files", but only a
   programs search is planned. Rename it, or order a file-search bridge?
5. **Orb size**: kept inside the 40px bar (Ø36). Win7's orb overhangs the
   taskbar; overhang needs a taller surface than the exclusive zone.
6. **Power split**: Lock as the default with Shut down in the ▸ menu — keep
   Restart/Shut down armed (second click) as specced?
7. **Lock name legibility**: the bare `$USER` label sits on bright art just
   under the tile; hyprlock's variables-only dress cannot add a plate, so any
   name band must be baked into the picture.
