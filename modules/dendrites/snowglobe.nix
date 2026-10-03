# snowglobe: disposable NixOS microVMs for agents (github: none yet, local repo).
#
# snowglobe ships its own option contract: `snowglobe.host.*` on the machine
# (kvm access, lingering, an optional dedicated partition) and `snowglobe.*` in
# home-manager (storage mode, budget, VMs). Like the aoide dendrite, this file is
# one import that brings both in; every knob that varies per host (budget,
# storage mode, the partition) is set by the host on the raw namespaces.
{
  nixos =
    { inputs, username, ... }:
    {
      imports = [ inputs.snowglobe.nixosModules.host ];
      home-manager.sharedModules = [ inputs.snowglobe.homeManagerModules.default ];
      snowglobe.host.users = [ username ];
    };
}
