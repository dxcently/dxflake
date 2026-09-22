# example-override.nix — a fix that belongs to a capability, not to a host.
#
# Copy to:  modules/overrides/<name>.nix
# Then:     nothing. modules/overrides/default.nix discovers every `*.nix` file
#           beside it. There is no catalogue line and no collector.
# Replace:  the targets, the host filter (or drop it), and the bodies.
#
# WHEN TO REACH FOR THIS. A package upstream broke, or a setting every machine
# that runs a thing needs, and the thing is selected on more than one host. The
# alternatives and why they are worse:
#   - repeating it in each host's `nixos` block — it drifts, and nothing ties it
#     to the capability it is about;
#   - putting it in the dendrite — the dendrite is what the thing IS, not a
#     patch log, and the fix leaves when upstream lands;
#   - a new aggregation or a new provider — a patch is not a capability and not
#     an implementation. Do not turn it into one.
#
# WHAT A RECORD DOES NOT DO. It never selects anything. Targeting a capability
# nobody chose is a record that does not apply — not a capability that gets
# installed.
#
# THE EVALUATION BOUNDARY, HONESTLY. Unlike an aggregation body, this file IS
# imported on every host: matching means reading which dendrites it targets.
# What an unmatched host never spends is the WORK — `overlay`, `nixos` and
# `homeManager` are functions, and nothing calls them. Keep every import,
# fetch and package computation inside those functions; metadata that computes
# defeats the boundary, and only the function bodies are proved cold.
{
  # ── Targets (required) ───────────────────────────────────────────────────
  # Catalogue names. The record applies here if ANY of them was selected on
  # this host — for the system or by one of its users, because a home lane
  # draws from the host's own package set. A name with no catalogue line is an
  # error naming this file, not a line that quietly matches nothing.
  dendrites = [ "exampletool" ];

  # ── Host filter (optional) ───────────────────────────────────────────────
  # Confine the record to named hosts. OMIT IT and the record reaches every
  # host that selected a target, which is the usual thing to want. Names are
  # checked against the host list in flake.nix, so a typo fails loudly.
  hosts = [ "examplehost" ];

  # ── A package fix (optional) ─────────────────────────────────────────────
  # An ordinary Nix overlay, applied to the HOST package set — there is no
  # private per-dendrite instance, and `useGlobalPkgs` means the home lanes see
  # it too. Matched records apply in record-name order and compose the ordinary
  # way, each seeing the previous as `prev`: on the same attribute the later one
  # wins, and nothing detects that for you.
  #
  # `overrideAttrs` on the packaged derivation is the cheap, honest shape. When
  # a fix needs a source pin instead, `src = final.fetchFromGitHub { … };` goes
  # here too — with a REAL hash. `lib.fakeHash` is a placeholder to build once
  # and replace from the mismatch error, never something to commit as a fix.
  overlay = _final: prev: {
    ripgrep = prev.ripgrep.overrideAttrs (_old: {
      doCheck = false;
    });
  };

  # ── A platform fix (optional) ────────────────────────────────────────────
  # An ordinary NixOS module, deferred exactly like a dendrite's `nixos` lane.
  # Ordinary merge rules apply: a plain definition that conflicts with the
  # dendrite's own is an error, `mkDefault` for a preference, and `mkForce`
  # only where replacing a definition is the deliberate point — as here.
  #
  # A record outranks everything the constructor imported on its behalf; the
  # host's own `nixos` module still outranks the record.
  nixos =
    { lib, ... }:
    {
      systemd.services.example.serviceConfig.DynamicUser = lib.mkForce false;
    };

  # ── A home fix (optional) ────────────────────────────────────────────────
  # This half rides only the users whose OWN home selection hit a target — not
  # every user on a matched host. One person's fix does not land in everyone
  # else's home.
  homeManager = _: {
    xdg.configFile."example/workaround.conf".text = ''
      # Upstream ignores the system-wide file; drop this until it does not.
      compat = true
    '';
  };

  # A record with none of the three above is an error: it carries nothing to
  # apply, which is a typo, not an intention.
}
