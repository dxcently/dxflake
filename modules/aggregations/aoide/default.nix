# aoide — Aoide's service floor for a host that runs Aoide: the daemon, the
# secrets broker, the Nix settings, the aoide binaries and the Melete adapter.
#
# Beside `core`, which every host carries. Aoide's own `aoide-config` is left
# out on purpose: selecting it would freeze the host's config.toml.
{
  description = "Aoide's service floor for a host that runs Aoide: the daemon, the secrets broker, the Nix settings, the aoide binaries and the Melete adapter.";

  system.members = [
    "aoide-nix"
    "aoide-packages"
    "aoide-secrets"
    "aoided"
    "melete-adapter"
  ];
}
