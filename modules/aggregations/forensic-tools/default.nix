# forensic-tools — imaging, triage and analysis of a disk that is not yours:
# Autopsy, ImHex, Guymager and The Sleuth Kit.
#
# ── Membership ────────────────────────────────────────────────────────────
# Two dendrites and two package lines, and nothing else: `autopsy` and
# `guymager` each own a file because their packaging needs a fix (a library
# path, a launcher entry and a polkit action installed where no daemon looks);
# `imhex` and `sleuthkit` are lines in modules/dendrites/packages.nix, which
# need no configuration at all. Membership is static — the list is the same
# whatever a host or one of its users answers elsewhere — and there is no
# provider to choose, since each of these is a single implementation.
#
# ── Why there is no home half ─────────────────────────────────────────────
# The one piece of this that is per-user — Autopsy's launcher entry — is already
# carried by the autopsy dendrite's own `habit.home`, so it rides whoever selects
# that dendrite and does not need repeating here. An absent half is a real
# answer, not a placeholder.
{
  description = "Forensic imaging and analysis: Autopsy, ImHex, Guymager and The Sleuth Kit.";

  system.members = [
    "autopsy"
    "guymager"
    "imhex"
    "sleuthkit"
  ];
}
