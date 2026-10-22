# fugue — Design Intent

**Rice:** fugue
**Thesis:** strict counterpoint — voices enter one after another on a fixed
lattice. Every element is a cell on a rigid grid; nothing is ornamental.

---

## The grammar

1. **ASCII only.** No Greek, no PUA, no emoji, no box-drawing. Permitted
   non-alphanumerics: `[ ] | > % + - # * .` and nothing else. A machine
   printout, not a typeset page.
2. **One typeface: `JetBrainsMono Nerd Font`**, every string, labels and
   values alike. Labels lowercase, values as-is. No serif anywhere.
3. **Zero radius, zero shadow, zero gradient, zero blur.** Every rectangle
   is a hard rectangle. Sonata is glass, pediments, and cast shadows; fugue
   is flat opaque paint.
4. **State is a rule, not a glow.** The live element wears a 2px solid
   underline or a filled block; there is no bloom, no pulse, no morph. One
   transition tier: `120ms` linear on colour only.
5. **Separators are 1px hairlines** in `base02`, never whitespace and never
   a bracketed cartouche.

## Palette rationale

| role | hex | reads as |
| --- | --- | --- |
| `bg` | `#0d0f12` | graphite black, cool-cast |
| `fg` | `#e4e6eb` | bone white |
| `accent` | `#3ddbd9` | signal teal — the chrome |
| `urgent` | `#ff5f56` | alarm red-orange |
| `hot` | `#c6f135` | acid lime — the one-hot trace |

## Component tier

`bar`/`notif` fall back to the palette (null in `rice.nix`). `window.border`
is the accent teal; `window.borderInactive` is `base02`, which recedes on
graphite without vanishing.

## Why a screenshot can never be confused with sonata

Four axes flip at once: polarity (near-black vs pale marble), temperature
(cool teal/lime vs warm gold/terracotta), typeface (mono-only vs Noto Serif
+ Noto Music + Libertine), and geometry (hard rectangles and hairlines vs
pediments, rounded glass, cast shadow).

## Slots dressed

Three: `bar` (the always-visible surface, `WidgetSlot`), `ricemode` (the
rice-mode control and its menu, a `WidgetSlot` the bar embeds as the
first cell of its right row) and `notifications` (the notification popup,
`SurfaceSlot`). `bar` and `notifications` are the two anchors that prove both
resolution paths; `ricemode` is dressed because the cell belongs to the
bar's own look, so fugue keeps it on the lattice instead of taking sonata's
floor. `launcher` and `powermenu` are cut as bodies but kept as behaviour:
the bar's `[pwr]` cell still calls the injected `powermenu` instance, and
both slots fall through to sonata's marble bodies via the baseline chain.
That is not a defect — it is the live proof that a minimal song is complete
because the fallback chain carries it.

## Cover

`wallpaper` is null; the stylix lane bakes a deterministic graphite solid
from `palette.bg`.

## Known hazard, not fixed here

The stylix lane pins `polarity = lib.mkDefault "light"`
(`modules/dendrites/stylix.nix`). A song may not set it — that is
a host/lane option, out of a song's reach under CONTRACTS §5. Quickshell
surfaces read `theme.*` directly and render fully dark and correct under
fugue regardless; Stylix-themed GTK/Qt apps may still pick light-variant
chrome. The fix, if wanted, is a host line (`stylix.polarity = "dark";`) —
out of scope for this song.

## How to fill this rice further

- Slot catalog: Aoide's `pkgs/strillix-shell/qml/slots.md` at revision bb5dbcca
- Rice widget contract: Aoide's `CONTRACTS.md` §5 at revision bb5dbcca
