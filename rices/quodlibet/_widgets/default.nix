# rices/quodlibet/_widgets/default.nix — the composition, not a shelf.
#
# quodlibet owns no widget records. It takes sonata's whole shelf, and fugue's
# bar, notifications and ricemode in place of sonata's, through the name-keyed
# `borrow` door (CONTRACTS.md §5). Every record keeps the `owner` its authoring
# rice bound, so quodlibet mints no `owner = "quodlibet"` record.
{ borrow, ... }:
let
  sonataWidgets = borrow "sonata";
  fugueWidgets = borrow "fugue";
in
sonataWidgets // { inherit (fugueWidgets) bar notifications ricemode; }
