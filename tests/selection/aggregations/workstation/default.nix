# A system-scope aggregation: a plain member, a provider-bearing member with a
# shared default, and a preference that rides along into the platform pass.
{
  description = "Select the workstation aggregation.";

  system = {
    members = [ "systemonly" ];
    providers.notifications = "dunst";
    nixos = {
      networking.hostName = "workstation-fixture";
    };
  };
}
