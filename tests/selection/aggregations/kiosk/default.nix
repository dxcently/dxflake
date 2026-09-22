# A second system-scope aggregation, choosing a different provider for the same
# dendrite. Enabling both must collide on dendrites.notifications.provider, not
# let import order decide.
{
  description = "Select the kiosk aggregation.";

  system.providers.notifications = "herald";
}
