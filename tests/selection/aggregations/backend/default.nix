# The shape modules/aggregations/hyprland/ has: an aggregation holding the
# members only ONE provider of a provider-bearing dendrite can run. Its member
# throws on import, so "picking the other provider never evaluates the
# backend-specific half" is proved rather than asserted.
{
  description = "Select the backend aggregation.";

  home.members = [ "landmine" ];
}
