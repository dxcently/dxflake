# barcarolle — intent

Windows 7 Aero, rebuilt as an AoideOS rice: a glass superbar along the bottom,
the Start orb and its Win7 Start menu, an iMac G3 app launcher on
SUPER+Space, white-plate flyouts and balloons (the agent sessions among
them), and CPU-meter gadgets, all over a teal
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
- **Aero Peek**: hover a button → a rim + deep header, a live miniature of
  the workspace, then the plate list of its windows; an agent's window
  carries its state dot and tool. The miniature is 240px wide in the
  monitor's aspect: each window streams into its real position over the
  song's cover at 15 fps, shown or hidden workspace alike, and the streams
  stop when the peek closes. A window that cannot be captured shows its icon.
  On a scrolling workspace the miniature is the stretch of the strip on the
  monitor, and a `+N` chip counts the windows scrolled off it.
- **Start**: the ♪ orb opens the Win7 two-column Start menu as `mock.html`
  draws it: pinned apps, All Programs ▸, "Search programs", the person
  tile, places, Terminal, Settings, and the Lock ▸ power split (Log off,
  Sleep, Hibernate, Restart, `Shut down…`). Power goes only through
  aoided's `power` command. Lock, Sleep and Hibernate act at once; Log off,
  Restart and `Shut down…` open the Shut Down dialog with that action
  preselected, so nothing that ends the session takes one click.
- **Launcher**: SUPER+Space opens the iMac G3 in the middle of the focused
  monitor; its screen is a Mac OS 9 Finder of apps, clipboard and emoji
  (see Launcher: iMac G3 below).
- **Shut Down dialog** (the powermenu): Win7's Alt+F4 dialog in the song's
  glass, a ♪ barcarolle banner, "What do you want the computer to do?" with
  Log off / Lock / Restart / Sleep / Hibernate / Shut down and a line
  describing the choice, OK / Cancel / Help, centred over a near-clear
  scrim. Escape cancels.
- **Agents dock** (the `dock` slot, `widgets/dock.qml` and
  `widgets/Buddy.js`; board `dock.png`, direction A): a Mac OS 8/9 Platinum
  buddy list, 384×713, anchored above the agents tray button `⧉` (whose
  badge counts the awaiting sessions) on the monitor whose bar was clicked;
  SUPER+G opens it too. A Platinum title bar with the counts and a recheck,
  then sessions grouped by workspace behind disclosure triangles (mini
  workspace button + label; click jumps; Elsewhere holds sessions with no
  window), rows with the agent's icon (28px) wearing its state orb, agent ·
  title, tool and cwd tail, and a context meter. Subagents indent. An
  awaiting row knocks: its ask with Approve / Deny, or "Answer in terminal"
  when the herald holds no summons. Under the list, a small room log
  (joins, leaves, state changes, herald toasts, asks), then `New terminal`.
  No text input anywhere. It closes on a click outside, Escape or its close
  box, and counts as the open flyout on its own monitor only.
- **RICE cell + menu**: the cell shows the mode glyph and word (`Stage`) with
  a chevron. The menu: header `Rice · <song> · <mode>`, songs with the
  current one ticked (staged / declared tags), `Back to declarative ·
  <declared>`, drafts of the current song, `+ New draft`, `Save current as
  draft`.
- **Tray flyouts**: the Win7 narrow volume flyout (device, slider, percent,
  mute, `Mixer` footer), the network flyout from its tray icon, and the
  calendar flyout from the clock (month grid, today ringed, an analogue
  clock beside it). The `^` chevron, shown while the tray holds an icon,
  opens the notification-area overflow: a 4-wide grid of the tray's icons
  on translucent deep glass, where the white symbolic icons most apps ship
  stay readable, and the hovered icon's title in white beneath. A click
  opens the icon's menu when it has one (so an icon with no Activate still
  answers a left click); otherwise left activates and right
  secondary-activates. An icon that publishes no picture shows an outlined
  box. One flyout is open at a time; opening one closes the
  rest, the RICE menu and the agents dock included. Each holds itself open
  with Hyprland's focus grab and closes on a click outside.
- **Action Center**: the ⚑ flag's flyout lists the notification ledger,
  newest first, with `Clear all`; the flag carries a dot while the ledger
  holds anything.
- **Balloon**: white plate whose tail points at the tray icon it belongs
  to; an agent summons points at the agents button and shows Approve / Deny
  pills.
- **Gadgets**: CPU (110px) and RAM (70px) dials, chrome bezels, white needles,
  readouts on dark chips; sits free on the desktop, Win7-style (top right on
  the board). Below them, the same family: a usage gadget (two 70px dials,
  5-hour and week, reset chips, a today · week cost chip; parked needles and
  `live usage unavailable` without data) and a power gadget (an inverted
  70px dial with state and time chips) that collapses to nothing on a
  machine with no battery.
- **Lock** (panel in the board, 0.45 scale): the logon picture with its baked
  person tile, the `$USER` label at −21% and the 400×60 hyprlock field at
  −26% below centre. Nothing else; the song supplies only the picture and
  colours (hyprlock dress contract).

## Launcher: iMac G3

SUPER+Space opens the app launcher: a large iMac G3 in Aero glass, centred
on the focused monitor. It pops in about its own centre with a small
overshoot; its CRT powers on, shows a pixel (・ω・) face for a beat,
then the Finder fades in on the screen. Closing reverses it: the Finder
fades, the CRT collapses to a dot and the G3 shrinks away. Boards:
`launcher-g3.html` (rendered to `launcher-g3.png`; the machine and its
timelines) and `launcher-finder.png` (the screen).

- **Look**: front-facing, no back. A front of translucent frosted plastic,
  symmetric about the screen centre, with a flat, low crown so the screen
  takes most of it. The ice gradient runs at 0.72 → 0.5 → 0.62 alpha, the
  feet at 0.6 and the teal speaker grilles at about 0.75, so the launcher
  layer's hyprglass blurs and warps the desktop through the plastic; an
  opaque outer rim, a white inner rim and the top highlight hold the
  silhouette. The dark CRT well and the screen stay solid for legibility,
  as does the drive slot between the grilles, with the power LED under it.
  No floor shadow: the G3 floats mid-screen, and the launcher layer's glass
  would smear a translucent shadow into a rainbow. No Apple logo.
- **Size and place**: a 760×480 viewBox at 1:1. The drawing fills only
  **x 0–504, y 24–480** of it (front shell x 2–502, y 26–446; feet to
  y 450), so the window is cropped to that 504×456 box and
  centred on the focused monitor's full output.
- **Screen rect** (where the content goes), in G3 units: the whole lit
  glass, **x 43, y 55, 418×318**, clipped to the glass curve itself (the
  `g3-screen.svg` path), so the desktop runs to the edges of the CRT.
- **Content**, a Mac OS 9 desktop on the screen (`launcher-finder.png`):
  a Platinum menu bar across the full width, its pixel ♪ Apple menu and
  titles set 56px in and its Find field ending 62px from the right, clear
  of the curve;
  the song's cover shrunk onto the little desktop (a teal dither without
  one), with this computer's disk (the Platinum drive, `finder-disk.svg`,
  labelled with the hostname) and the Trash in the bottom-right corner,
  10px up; the disk's window, titled with the
  hostname, holding
  four folders, Applications, Clipboard, Emoji and Kaomoji, in icon view. Each
  level opens its window in front while its parent greys behind, cascading
  14px right and 18px down. Applications are the desktop entries A→Z with
  their icons; Clipboard shows text and picture clippings (pictures as
  thumbnails). Emoji holds nine folders, the Unicode groups in CLDR order
  (Smileys & Emotion … Flags), each an 8-wide grid of glyphs from
  `widgets/Emoji.js`. Kaomoji holds ten mood folders (Happy & Joy … Sleepy
  & Faint), each a one-column list from `widgets/Kaomoji.js` (Noto Sans CJK
  JP Medium 12, the mood dim beside each). Every subfolder is the one
  lavender `finder-folder.svg` with its emblem, a glyph or kaomoji, drawn
  over it in QML. Selection is `#0f6d80` with white text; a help balloon
  names the selected emoji or shows a clipping's text; the status line
  reads "x items, 1 selected". Tahoma 12 and Verdana 10 stand in for
  Charcoal and Geneva.
  - Keys: typing in Emoji or Kaomoji searches its whole subtree, typing in
    a subfolder filters it, and typing at the top opens a `Find "q"` window
    over all four; arrows move; Enter opens a folder, launches an app (a
    `systemd-run --user --scope`) or copies a clipping, emoji or kaomoji
    (`wl-copy`), then closes; Backspace on an empty query goes up one level
    and reselects the folder it came from; Escape closes, and the next open
    starts at the top. The `clipboard` shortcut opens straight to Clipboard.
  - Scanlines over the content: a 1px line every 3px of `#021219` at 0.06.

### Layers

`icons/launcher/`, all on one 760×480 viewBox, stacked at the same
geometry, bottom → top. Static SVG Tiny (gradients only; no filters,
masks, clips or text), so QtSvg renders them as Chromium does.

| layer | holds | animated |
|---|---|---|
| `g3-body.svg` | feet, front, dark screen, speakers, slot, dull LED | with the whole G3 |
| `g3-screen.svg` | the lit screen glass | opacity, yScale, brightness |
| `g3-face.svg` | the pixel (・ω・) face on the lit screen | opacity, yScale, brightness (with the screen) |
| *content* | the Finder (QML), in the screen rect | opacity |
| `g3-beam.svg` | the CRT line: white core, hot centre, cyan halo | opacity, xScale |
| `g3-glare.svg` | the vignette (curvature), the diagonal sheen, the top highlight | never |
| `g3-led.svg` | the lit LED and its halo | opacity |

- The screen, face and beam scale about the screen centre, (252, 214).
- The whole G3 scales about its own centre, (252, 252) in G3 units.
- Brightness is a `MultiEffect.brightness` on the screen and face.
- Every art URL carries a per-load `?v=` stamp: Qt's image cache lives as
  long as the shell process and is keyed by URL alone, so without it a
  reload keeps drawing art the song has since changed.

### Open, 460 ms

t = 0 is the keypress. Before it every value is at rest: G3 opacity 0, scale
0.12; led 0; beam 0, xScale 0.1; screen and face opacity 0, yScale 0.02,
brightness 0; content 0. A track holds its last value after its end.

| t (ms) | layer · property | value | easing |
|---|---|---|---|
| 0 → 60 | G3 · opacity | 0 → 1 | Linear |
| 0 → 170 | G3 · scale | 0.12 → 1.04 | OutCubic |
| 170 → 230 | G3 · scale | 1.04 → 1 | InOutQuad (settle) |
| 180 / 205 / 230 | led · opacity | 1 / 0.25 / 1 | step (flicker) |
| 200 → 230 | beam · opacity | 0 → 1 | OutQuad |
| 200 → 250 | beam · xScale | 0.1 → 1 | OutCubic |
| 250 | screen, face · opacity | 1 | step |
| 250 → 330 | screen, face · yScale | 0.02 → 1 | OutCubic |
| 250 → 300 | beam · opacity | 1 → 0 | Linear |
| 250 → 330 | screen, face · brightness | 0.6 → 0.25 | Linear (bloom) |
| 330 → 460 | screen, face · brightness | 0.25 → 0 | OutQuad (settle) |
| 340 → 420 | face · opacity | 1 → 0 | Linear |
| 340 → 440 | content · opacity | 0 → 1 | OutQuad |

### Close, 320 ms

t = 0 is the keypress, from the open values.

| t (ms) | layer · property | value | easing |
|---|---|---|---|
| 0 → 70 | content · opacity | 1 → 0 | InQuad |
| 40 → 80 | screen · brightness | 0 → 0.5 | Linear |
| 60 → 140 | screen · yScale | 1 → 0.02 | InCubic |
| 140 | screen · opacity | 0 | step |
| 140 | beam · opacity, xScale | 1, 1 | step |
| 140 → 190 | beam · xScale | 1 → 0.03 | InCubic (line → dot) |
| 190 → 230 | beam · opacity | 1 → 0 | Linear (afterglow) |
| 190 | led · opacity | 0 | step |
| 200 → 320 | G3 · scale | 1 → 0.12 | InCubic (shrinks away) |
| 260 → 320 | G3 · opacity | 1 → 0 | Linear |

A toggle mid-animation stops the running timeline and starts the other.
Each eased track animates from its current value instead of its listed
start; step tracks still fire, and a step whose time has already passed in
the new timeline fires at once.

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
| hermes | Hermes Agent's CLI emblem, a caduceus: a plain staff of even width under a small flat cap; two headless serpents in a loose double helix, much wider than the staff, crossing it three times and tapering onto it under the wings and at the foot, each crossing with one strand in front casting a small shadow and the other passing behind, darkening where the staff covers it; heraldic wings rising up and out from the staff, three rows of rounded-pointed feathers whose primaries fan outward and upward to the upper corners; a warm glow behind | near-black `#2a2a22` → `#0b0b08` | gold `#fff6a8` → `#ffe14a` → `#f0b400`, outline and row lines `#a07800`, the hidden side of the coils `#6e4c00` |
| agent | a glass orb holding a node and three satellites | base0C `#4fd8e6` → `#0a3242` | white |

claude's golden spark sits on a cream tile: on a gold tile the rays sink
into the ground at 16px, on cream they hold. kimi sits on indigo so its tile
never reads as eidolon's blue at 16px; at 16px the disc keeps two or three
of its black-key notches and only the brightest star survives. At 16px hermes reads as a
gold Y of wings over a ribbed column; its dark tile keeps the
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
  baked frost (no compositor rule); popups get `blur_popups`; the
  agents dock gets hyprglass. The G3 is drawn art and needs no blur.
- **Icons**: all drawn here; the real bar resolves app icons from the icon
  theme. Agent icons: see above.
- **Start**: `mock.html` draws the orb's Start menu; the G3 launcher is on
  `launcher-g3.html` and `launcher-finder.png` only.
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
2. **Orb size**: kept inside the 40px bar (Ø36). Win7's orb overhangs the
   taskbar; overhang needs a taller surface than the exclusive zone.
3. **Lock name legibility**: the bare `$USER` label sits on bright art just
   under the tile; hyprlock's variables-only dress cannot add a plate, so any
   name band must be baked into the picture.
