# songbook

dxflake's rices. One directory each, `default.nix` is the provider registry.

A **rice** is the look: the palette, and the stylesheets the surfaces wear. It
is not the wiring. Whether waybar runs, whether rofi is installed, which
systemd target the bar rides — those live in `modules/dendrites/`, where any
rice reuses them. Swapping the rice must never mean re-deciding whether the bar
exists.

```
song/
├── songbook/
│   ├── default.nix              the registry: names paths, imports none
│   └── transience/
│       ├── rice.nix             the composition — a homeManager lane
│       ├── palette.nix          the palette, the one source
│       ├── livery.json          generated from palette.nix, Aoide's v0 livery schema
│       ├── regen-livery.sh      writes livery.json from palette.nix
│       ├── design/intent.md     what this look is, and what it deliberately omits
│       └── source/waybar.css    owned source, a {{base16.baseXX}} template
├── covers/                      the cover art, shared by every rice
└── stage/                       runtime only, gitignored — never committed
```

`covers/` is the cover art — what the compositor sets as the wallpaper, and
what Aoide's picker enumerates. It sits beside the songbook, not inside it,
because an image is not a look: any rice may wear any cover, and osaka deploys
the whole directory to `~/.aoide/song/covers` so the picker has a library. The
name mirrors Aoide's `song/covers/`, and the registry names its providers by
hand, so a directory here is never mistaken for a rice.

Selected through the `shell` aggregation, which answers with `transience` by
default because dxflake ships one rice and that is the look this desktop has
always had:

```nix
users.khoa.aggregation.shell.rice.provider = "transience";
```

The registry imports nothing, so an unselected rice is never read — same
guarantee as `modules/dendrites/compositor/` and proved by the same fixture in
`tests/selection`.

## Why the layout mirrors Aoide's `song/songbook/`

Because the palette format is genuinely shared. `livery.json` is generated
from `palette.nix` in Aoide's v0 livery schema, so `lyra livery lint`,
`livery resolve` and `livery emit` all work on a rice here unchanged, and
`source/waybar.css` uses Lyra's own `{{group.key}}` template syntax —
`tests/rice` asserts that the Nix render and `lyra livery emit file` produce
the same bytes.

What is **not** shared: a song in Aoide's songbook is a QML rice, with widget
bodies mounted into Quickshell by `aoide.arrangement`. Nothing in that schema
can carry a GTK stylesheet, and `lyra rice declare` copies a song into the
*Aoide* checkout. So `rice compose/stage/draft/take/declare` do not apply to a
rice here, nothing in this directory is declared into Aoide, and nothing here
stages or hot-loads. See `transience/design/intent.md` for the full boundary.

## Adding a rice

A directory beside `transience/`, one line in `default.nix`, and the host that
wants it names it. Author `palette.nix`, generate `livery.json` from it, and
lint the result:

```sh
song/songbook/<name>/regen-livery.sh
lyra livery lint song/songbook/<name>/livery.json
./tests/rice/run.sh
```
