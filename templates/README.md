# templates/

Copyable starting points, one per authoring role. Nothing here is imported by
anything: no catalogue line names these files, `modules/aggregations/default.nix`
does not discover this directory, and `flake.nix` never sees it. **Copying a
template does not enable it** — a dendrite goes live when the catalogue names it
*and* something selects it; an aggregation goes live when it sits in
`modules/aggregations/<group>/` *and* a host selects it by name; an override
record goes live when it sits in `modules/overrides/` *and* a host selected one
of the capabilities it targets.

Read `../AGENTS.md` for where things live and `~/Aoide/docs/architecture/NIX-COMPOSITION.md`
for why. Verify a copy with `../tests/selection/run.sh`; verify the templates
themselves with `../tests/templates/run.sh`, which assembles a whole tree out of
this directory, resolves two hosts against the real constructor, and checks that
files nobody selected stayed unread.

## The map

| I want to add… | Copy | To | Then |
|---|---|---|---|
| a capability with one implementation | `example-dendrite.nix` | `modules/dendrites/<name>.nix` | one catalogue line; select it |
| a capability with several | `example-default-provider-registry.nix` | `modules/dendrites/<name>/default.nix` | one catalogue line naming the **directory** |
| one of those implementations | `example-provider.nix` | `modules/dendrites/<name>/<provider>.nix` | one line in that directory's `default.nix` |
| a group of capabilities | `example-aggregation.nix` | `modules/aggregations/<group>/default.nix` | nothing — discovery finds it; select it from a host |
| a new look (a rice) | `example-provider.nix` | `songbook/<name>/rice.nix` | one line in `songbook/default.nix`; author `livery.json` beside it and lint it with `lyra livery lint` |
| a machine | `example-host.nix` | `hosts/<host>/default.nix` | add `"<host>"` to the host list in `flake.nix` |
| a headless machine | `example-host-headless.nix` | `hosts/<host>/default.nix` | same |
| a person | `example-user.nix` | `users/<name>.nix` | attach from each host that wants them |
| something every host gets | `example-nucleus-module.nix` | `modules/nucleus/<topic>.nix` | one import line in `modules/nucleus/default.nix` |
| a package nixpkgs lacks | `example-package.nix` | `pkgs/<name>/default.nix` | `pkgs.callPackage` it from the lane that wants it |
| a fix a capability needs everywhere | `example-override.nix` | `modules/overrides/<name>.nix` | nothing — discovery finds it; it applies where a target was selected |
| a whole new tree | `example-default-registry.nix`, `example-default-aggregations.nix`, `example-default-overrides.nix` | `modules/default.nix`, `modules/aggregations/default.nix`, `modules/overrides/default.nix` | these three are the floor everything else plugs into |

`example-host.nix` and `example-host-headless.nix` are one role answered twice —
read them side by side. They share a group, choose different implementations of
the same capability, and one has a Home Manager lane while the other has only an
account.

## What the templates assume you replace

Every file opens with a `Copy to:` / `Then:` / `Replace:` header. Beyond that,
four things are placeholders and will not work as shipped:

- `hashedPassword = "!"` in `example-user.nix` — generate your own, or move it
  to sops-nix and use `hashedPasswordFile`.
- `lib.fakeHash` in `example-package.nix` — build once and copy the real hash
  out of the mismatch error.
- `./hardware.nix` in both host templates — generate yours with
  `nixos-generate-config`. The hardware in this tree's hosts is specific to
  those machines and is not a template.
- the `ripgrep` overlay and the `systemd.services.example` fix in
  `example-override.nix` — a shape to copy, not a fix anyone asked for. Ship a
  record only for a problem you have actually verified.

The generic names (`exampletool`, `examplewidget`, `workspace`, `exampleuser`)
are meant to be renamed. The `services.example.*` / `programs.example.*`
settings inside the lanes are stand-ins for real options.

## Lanes, in one paragraph

A dendrite names the evaluators it answers for. `nixos` is the host's NixOS
module — services, system packages, hardware. `homeManager` is one user's Home
Manager module — dotfiles, user packages. `darwin` is nix-darwin; it is in the
vocabulary and unused in this tree. Selecting a capability for the system
imports its `nixos` lane and *not* its `homeManager` lane; selecting it under
`users.<u>` does the reverse. Something that wants both is selected in both
places, visibly. Selecting a lane a dendrite does not expose is an error naming
the dendrite, the scope, and the lanes it does support — never a silent skip.

Home Manager is optional per user. `homeManager.enable = false` creates the
account and imports no Home Manager module at all; asking for a home capability
with that lane off is a configuration error, not a no-op.

## Selection happens before imports

The constructor resolves the whole selection — aggregations, capabilities,
providers, per-user choices — with an ordinary `lib.evalModules` pass that knows
nothing about NixOS, and only then builds the import list. That is why an
implementation the host did not choose costs nothing: it is never `import`ed, so
a broken or expensive file beside the one you picked cannot affect you. The
boundary, exactly:

```text
modules/aggregations/default.nix   names directories, imports no body
       ↓
gate step    which aggregations did this host or its users select?
       ↓
select step  import THOSE bodies; they declare their provider selectors and
             write their membership. No other body is read.
       ↓
platform     import the chosen dendrite files and the chosen provider files.
             Nothing else in modules/dendrites/ is read at all.
```

Override records are the documented exception — see below.

An aggregation body is data — `members`, `providers`, `nixos` — so it cannot
enable another aggregation, and the gate step's answer is final. That is also
why a body needs no `mkIf` and no `mkOption` of its own: the constructor wraps
it once.

## Selection priority, in order

Membership and provider choices from an aggregation are `mkDefault`, so:

- `dendrites.<name>.enable = false` on a host beats a group that wants it.
- `dendrites.<name>.provider = "x"` on a host beats a group's choice.
- Two groups naming the same capability on the same terms **merge** — one
  selection, not two instances.
- Two groups naming **different** providers for it collide, with both values in
  the error. Import order never picks a winner.

## Override records

`example-override.nix` is the odd one out and worth reading before you copy it.
A record is a fix that belongs to a CAPABILITY — a package upstream broke, a
setting every machine running the thing needs — and it lives in
`modules/overrides/<name>.nix` rather than in every host that selected the
thing. It names its targets by catalogue name, optionally confines itself to
named hosts, and carries an `overlay`, a `nixos` module, a `homeManager` module,
or any combination.

A record **never selects anything**: targeting a capability nobody chose is a
record that does not apply, not a capability that gets installed. It applies at
most once however many of its targets were selected, matched records apply in
record-name order, and its overlay goes on the HOST package set — `useGlobalPkgs`
means the home lanes see it too, and there is no private per-dendrite instance.
Its `homeManager` half rides only the users whose own selection hit a target.

The evaluation boundary is weaker here than for selection, and saying so is the
point: a record file IS imported on every host, because matching means reading
which dendrites it targets. What an unmatched host never spends is the work —
`overlay` and the lane modules are functions, and nothing calls them. Keep
imports, fetches and package computation inside those functions.

## Pending: songs and palettes

There is no template for a Lyra song or palette yet. Aoide's flake exports
`packages`, `songbookManifest` and `aoideOptions` — no `nixosModules`, no `lib`,
and no public authoring contract to write one against, so a template here would
be invented rather than supported. The real examples live in Aoide's own
`song/songbook/<name>/rice.nix`, and the design is
`~/Aoide/docs/architecture/NIX-COMPOSITION.md` § Lyra and songbook.
This gets a template when that contract is public.
