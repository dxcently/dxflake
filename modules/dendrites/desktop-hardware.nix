{
  nixos =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      config = {
        hardware = {
          opentabletdriver = {
            enable = true;
            daemon.enable = true;
          };
          keyboard.qmk.enable = true;
        };
      };
    };
}
