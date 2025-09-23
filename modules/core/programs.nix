{
  pkgs,
  config,
  ...
}: {
  programs = {
    starship.enable = true;
    dconf.enable = true;
    bash.blesh.enable = true;
    nm-applet.enable = true;
    virt-manager.enable = true;
    system-config-printer.enable = true;
  };
  nixpkgs = {
    config = {
      permittedInsecurePackages = ["qtwebengine-5.15.19"];
    };
  };
}
