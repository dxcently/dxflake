{
  habit.home =
    {
      pkgs,
      config,
      inputs,
      ...
    }:
    {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;
      };
    };
}
