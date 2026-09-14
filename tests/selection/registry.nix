# The fixture registry: the catalogue the selection cases select from, and the
# aggregations discovered beside them. Deliberately includes implementations and
# an aggregation body that throw when imported — that is how "an unselected file
# is never evaluated" is proved rather than asserted.
{
  catalogue = {
    homeonly = ./dendrites/homeonly;
    landmine = ./dendrites/landmine;
    notifications = ./dendrites/notifications;
    systemonly = ./dendrites/systemonly;
  };

  aggregations = import ./aggregations;
}
