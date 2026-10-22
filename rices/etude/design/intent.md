# etude — Design Intent

**Rice:** etude
**Palette/geometry:** inherited from `sonata` — retune

**Throwaway proof-of-concept.** `etude` exists solely as Phase 6's
end-to-end demo for the declared widget-type registry feature
(`aoide.arrangement.widgets` — CONTRACTS.md §5, `modules/nucleus/options.nix`).
It declares one `demo` surface widget (`widgets/demo.qml`) to prove the whole
pipeline (nix option → build-time `registry.json` walk → `rice lint`
validation → `rice stage` hot-sync → `SongSurfaces.qml` runtime) actually
renders something on screen. Not a real dressed song — no design intent
beyond that.

---

## Palette Rationale

(not yet written — this rice was scaffolded from `sonata` via `aoide rice compose`, not designed)

## Component Tier

(not yet written)

## Geometry

(not yet written)

## Iteration Log

## How to fill this rice

- Slot catalog: Aoide's `pkgs/strillix-shell/qml/slots.md` at revision bb5dbcca
- Rice widget contract: Aoide's `CONTRACTS.md` §5 at revision bb5dbcca
- Drop a `widgets/<slot>.qml` here to dress a slot — any file under `widgets/` becomes a slot named for its basename; nothing renders until a host surface embeds a `WidgetSlot` anchor for that name.
