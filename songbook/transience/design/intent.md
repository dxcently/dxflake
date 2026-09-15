# transience

The look this desktop has worn since before it had a name for it. A dark Rosé
Pine ground, a nearly transparent bar with hard black rules, workspace pills
lit by a radial highlight, and white glyphs carrying a one-pixel black outline
so they stay readable over any wallpaper. Nothing here is new. Writing it down
is the whole point: it was scattered across three dendrites and a fixed palette
in the Stylix module, and a look that exists only as a side effect of where its
pieces happen to live cannot be preserved, replaced, or compared against
anything.

## What the name means

A rice you can name is a rice you can leave. transience is the first, so it is
also the proof that a second one is a directory and one line rather than a
rewrite of three dendrites.

## The palette

Rosé Pine, dark, the sixteen in `palette.nix` — the one source. Both consumers
read it rather than hold their own copy: `modules/dendrites/stylix.nix` reads
`palette.nix` directly for the scheme it pins to Stylix, the fan-out that
paints GTK, Qt, kitty and the rest and stays the floor's business; `livery.json`
is `regen-livery.sh`'s output, transience's generated record in Aoide's v0
livery schema. Neither can drift from `palette.nix`, because neither carries
its own hexes to drift with — `tests/rice`'s `liveryJsonIsGenerated` and
`liveryMatchesStylixScheme` cases exist to catch a checked-in `livery.json`
that fell out of sync, or a real host that stopped reading `palette.nix` at
all.

Generating `livery.json` in Aoide's schema is not decoration. It means
`lyra livery lint songbook/transience/livery.json` is a real check,
`lyra livery resolve` prints the resolved set, and `lyra livery emit` can drive
the very same stylesheet template this rice renders through Nix. Both renderers
were run against `source/waybar.css` and agree byte for byte.

## What each surface contributes

**waybar** — everything. `source/waybar.css` is the stylesheet, and `rice.nix`
carries the bar's own composition: which modules sit left, centre and right,
and how each one reads. The sheet is a template with `{{base16.baseXX}}`
placeholders, Lyra's own syntax, filled at build time from the live Stylix
palette — which is exactly what the sheet read before it was a file, so a host
whose colours are repainted by Aoide's stylix facet is still repainted.

**rofi** and **wlogout** — nothing bespoke, and that is a finding rather than
an omission. Neither ever had a stylesheet of its own; both take the base16
scheme through Stylix, and wlogout's six entries are actions, not look, so they
stay in the dendrite. Inventing sheets for them here would be a redesign of a
rice whose brief was to preserve it.

**the dock** — also nothing, for a different reason. dxflake ships no dock. The
dock on screen is Aoide's Quickshell `aoide-dock` surface; dxflake only
references its namespace, in `hyprland/hyprglass.nix`'s layerrules and in one
keybind. Preserving it means not substituting one and not drawing a second
surface beside it. transience carries the same palette into it through the
shared livery instead.

**the wallpapers** — `songbook/covers/`, set by `awww img` from the autostart
dendrite. They are content, not rice, and stay shared: a second rice should be
able to keep the same picture.

## What Lyra can and cannot do with this

Works, verified: `livery lint`, `livery resolve`, `livery emit file|hyprctl|osc`.

Does not apply: `rice compose`, `rice stage`, `rice draft`, `rice take`,
`rice declare`. Those are the QML self-ricing loop — a song is `livery.json` +
`rice.nix` + QML widget bodies mounted into Quickshell, and `rice declare`
copies a song into the *Aoide* checkout. transience has no QML and is not
Aoide's to hold. There is no widget kind, slot, or arrangement entry that can
carry a GTK stylesheet, so staging and hot-load genuinely do not reach it.

That is the honest boundary, and it is not a defect in Lyra: a Quickshell rice
engine is not obliged to theme GTK apps. The livery half — the palette, the
schema, the emitters — is shared, and that is the part worth sharing.
