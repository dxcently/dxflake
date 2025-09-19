{
  pkgs,
  config,
  inputs,
  ...
}: {
  hardware = {
    opentabletdriver = {
      enable = true;
      daemon.enable = true;
    };
    keyboard.qmk.enable = true;
  };
}
