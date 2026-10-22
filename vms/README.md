# vms

`vms/` holds the presets snowglobe VMs are built from, one `<name>.nix` each: a whole habit host (its selection, and `habit.users.agent` for the agent's home).
`snowglobe summon <vm> --preset <name>` builds a VM from one; a VM takes a preset or picks, not both.
`_`-prefixed files are parked, and `lib.snowglobeOffer` does not list them.
