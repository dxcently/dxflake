# barcarolle — intent

Windows 7 Aero, rebuilt as an AoideOS rice: a glass superbar along the bottom,
the Start orb and its two-column menu, white-plate flyouts and balloons
(the agent sessions among them), and a CPU-meter gadget, all over a teal
Frutiger Aero wallpaper. The one structural change from Windows 7: the grouped taskbar
buttons are **Hyprland workspaces**, not applications.

The board is `mock.html` (rendered to `mock.png`). It holds every summoned
surface open at once on one 1920×1080 output, which the real desktop never
does. It is a reference for the QML, not a spec of behaviour.

## Grammar

Glass is a frame, content is a plate, light comes from above.

- **Deep glass** (`bar.bg`) is the only glass that carries text, always white.
- **Colorization** (`window.border`) tints every frame — Start rim, flyout
  rims, peek frame, active window border — and never carries
  text.
- **Plates** (`notif.bg` at 0.97, 1px ink-0.55 border) carry every list,
  grid, paragraph and field; ink text on them.
- Colour on glass appears only as gloss pills and badges with ink labels,
  progress washes, and the `bar.accent` glow.
- Light: a 1px white top highlight, a hard-stop gloss over the top half,
  faint diagonal streaks.

## Layout (DP-1, 1920×1080)

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                                                         [CPU/RAM gadget]       │
│                                                                                │
│                                                         ┌balloon────────────┐  │
│ ┌Start──────────┐                                       │ approve/deny      │  │
│ │ pinned │ name  │                                      └──────┬────────────┘  │
│ │ recent │ places│                  ┌vol┐ ┌RICE menu┐ ┌Agents──┊────────────┐  │
│ │ All ▸  │       │   ┌Peek ws7┐     │   │ │ songs   │ │ sessions by ws      │  │
│ │ search │ Lock ▸│   │ rows   │     │   │ │ drafts  │ │ + New terminal      │  │
├─┴───────┴───────┴──────────────────────────────────────────────┊───────────────┤
│◉ [1][2][3][4][5][6][7][8] ┆ mag scr +                 Stage▾ ^ ⧉ ⚑ ▭ ◁)) 3:42 ▐│
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
- **Agent flyout** (352px, from the agents tray button `⧉`, whose badge
  counts the awaiting sessions): a Win7 notification-area flyout anchored
  above its button at the bottom right, one flyout open at a time like the
  rest. Rim + deep header with the counts and a recheck, then one plate of
  sessions grouped by workspace (mini workspace button + label; click jumps),
  rows with the agent's icon (28px) wearing its state orb as an overlay,
  agent · title, tool and cwd tail, and a context meter. Subagents indent.
  "Elsewhere" holds sessions with no window. `+ New terminal` at the foot.
- **RICE cell + menu**: the cell shows the mode glyph and word (`Stage`) with
  a chevron. The menu: header `Rice · <song> · <mode>`, songs with the
  current one ticked (staged / declared tags), `Back to declarative ·
  <declared>`, drafts of the current song, `+ New draft`, `Save current as
  draft`.
- **Tray flyout**: the Win7 narrow volume flyout (device, slider, percent,
  mute, `Mixer` footer).
- **Balloon**: white plate whose tail points at the tray icon it belongs
  to; an agent summons points at the agents button and shows Approve / Deny
  pills.
- **Gadget**: CPU (110px) and RAM (70px) dials, chrome bezels, white needles,
  readouts on dark chips; sits free on the desktop, Win7-style (top right on
  the board).
- **Lock** (panel in the board, 0.45 scale): the logon picture with its baked
  person tile, the `$USER` label at −21% and the 400×60 hyprlock field at
  −26% below centre. Nothing else; the song supplies only the picture and
  colours (hyprlock dress contract).

## Agent states

The canonical five from `sessions.json`: `working` (base0B green) ·
`awaiting` (base0A yellow, pause bars — the one that is *asking*) · `idle`
(base04 grey) · `stopped` (white orb with an ink stop square) · `done`
(accent with a check).

## Agent icons

`icons/agents/<kind>.svg`, one per session kind `aoide session` reports;
contact sheet `agent-icons.png`. One family: a 48×48 glass tile (the
fallback is an orb), a vertical body gradient in the kind's hue, a bottom
bounce glow, a curved hard-edged gloss over the top half, a white inner rim
and a dark outer rim. The mark sits above the gloss with a 1.2px dark drop so
it holds at 16px. Five kinds wear their owners' marks, drawn here as plain
geometry: claude after Anthropic's Claude spark and codex after the OpenAI
blossom, both from memory, and kimi after Moonshot AI's mark from the user's
reference (trademarks, used on the user's own desktop by the user's ruling);
eidolon after its own helmet figure (the user's project); hermes after
Hermes Agent's CLI emblem (Nous Research), from the user's screenshot. shell
and agent are original.

| kind | mark | body (top → bottom) | mark colour |
|---|---|---|---|
| claude | Claude's spark: ten tapered rays of uneven length and width with rounded tips around a small centre, as smooth warm metal with no shine stripe: a thin terracotta rim, a warm glow behind the centre | cream `#fffaf2` → `#ecd3bd` | golden amber `#ffd877` → `#ffc35e` → coral `#e8875a` → terracotta `#c2593a`, rim `#9a3d1e`, glow `#ffd27a` |
| eidolon | eidolon's helmet figure, a Corinthian helmet front-on in hard pixel blocks on a 6-unit grid (2px at 16): crest, crown, brow, eye slit split by the nasal, two cheek guards | the wordmark's blue `#2f7fd8` → cyan `#2ecfcf` | yellow `#ffc23a` → amber `#ffa43a` → orange `#ff8a2a`, interior `#1a1a28` |
| kimi | Moonshot AI's mark, traced with potrace from the user's reference (it resembles a piano and its keys): a round disc cut by four thin parallel gaps that fall gently to the right; on the right half each gap widens into a dark notch, a black key, whose left end steps in at a staggered point (the top step slanted, the lower ones near-vertical), so the white bands read as keys; the outline stays round all the way, the keys end at the circle's edge; the gaps are cut through to the tile; a sparse starfield around: three 4-point twinkles and a scatter of dots of uneven size and brightness | indigo `#5560d6` → night `#170f52` | white → `#eef0f8` → `#b9bfd6` with a soft highlight; stars pale gold `#fff3c4` and white |
| codex | the OpenAI blossom, six rounded links around a hexagonal eye, in glossy glass | green `#2fae72` → `#0c4a2e` | white → `#f0fff6`, hard stop, `#cdf5df` → `#93dcb6`, rim `#0a4429` |
| shell | the `>_` prompt | graphite `#4e5f6b` → `#0b1419` | base0B `>`, plate-white `_` |
| hermes | Hermes Agent's CLI emblem, a caduceus: a staff with a small round finial; two long tapering wings attached below the top, sweeping up and out in a shallow V above the finial, each fanning four pointed primary feathers at the tip with clear notches and two quill lines; two serpents coiling down the staff, their small heads facing each other just under the wings; a warm glow behind | near-black `#2a2a22` → `#0b0b08` | gold `#fff6a8` → `#ffe14a` → `#f0b400`, outline and quill lines `#a07800` |
| agent | a glass orb holding a node and three satellites | base0C `#4fd8e6` → `#0a3242` | white |

claude's golden spark sits on a cream tile: on a gold tile the rays sink
into the ground at 16px, on cream they hold. kimi sits on indigo so its tile
never reads as eidolon's blue at 16px; at 16px the disc keeps two or three
of its black-key notches and only the brightest star survives. At 16px hermes reads as a
gold winged staff and the coils simplify to bumps; its dark tile keeps the
gold apart from claude's spark on cream. An unknown kind takes `agent`.
Gradient ids are prefixed with the kind, so all seven inline together
without collision.

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
  agent flyout get hyprglass.
- **Icons**: all drawn here; the real bar resolves app icons from the icon
  theme. Agent icons: see above.
- **Data**: workspaces, sessions, songs and drafts are hard-coded sample
  data. Nothing reads `desktop.json`, `sessions.json` or `mode.json`.
- **Board-only placement**: every surface is open at once, though only one
  flyout opens at a time. The peek is shifted right to clear the open Start
  menu; the agent flyout sits over its button, so the RICE menu and the
  volume flyout are shifted left of it; the balloon is lifted above the open
  agent flyout with a dashed leader down to the agents button.
- Not shown: the HDMI-A-1 compact bar, jump lists, chevron overflow grid,
  network and calendar flyouts, Action Center, power screen, window frames
  and terminals.

## Open questions

1. **"awaiting" vs "asking"**: display the canonical word, or map it to
   "asking" in the UI only?
2. **Start search**: the placeholder says "programs and files", but only a
   programs search is planned. Rename it, or order a file-search bridge?
3. **Orb size**: kept inside the 40px bar (Ø36). Win7's orb overhangs the
   taskbar; overhang needs a taller surface than the exclusive zone.
4. **Power split**: Lock as the default with Shut down in the ▸ menu — keep
   Restart/Shut down armed (second click) as specced?
5. **Lock name legibility**: the bare `$USER` label sits on bright art just
   under the tile; hyprlock's variables-only dress cannot add a plate, so any
   name band must be baked into the picture.
