# Home-only provider: selecting it for the system must fail, not be skipped.
{
  homeManager = { ... }: { fixture.notifications = "mako"; };
}
