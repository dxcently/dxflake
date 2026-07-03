{config, lib, ...}: {
  options.dx.laptop.enable = lib.mkEnableOption "laptop";
  config = lib.mkIf config.dx.laptop.enable {
    services.auto-cpufreq.enable = true;
    services.auto-cpufreq.settings = {
      battery = {
        governor = "powersave";
        turbo = "never";
      };
      charger = {
        governor = "performance";
        turbo = "auto";
      };
    };
    networking.networkmanager.wifi.powersave = false;
  };
}
