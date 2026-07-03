{
  pkgs,
  config,
  lib,
  ...
}: {
  options.dx.solaar.enable = lib.mkEnableOption "solaar";

  config = lib.mkIf config.dx.solaar.enable {
    services.solaar = {
      enable = true; # Enable the service
      package = pkgs.solaar; # The package to use
      window = "hide"; # Show the window on startup (show, *hide*, only [window only])
      batteryIcons = "regular"; # Which battery icons to use (*regular*, symbolic, solaar)
      extraArgs = ""; # Extra arguments to pass to solaar on startup
    };
  };
}
