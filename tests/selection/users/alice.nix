{
  nixos = { ... }: { fixture.account.alice = true; };
  homeManager = { ... }: { fixture.home.alice = true; };
}
