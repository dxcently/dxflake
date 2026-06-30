{
  pkgs,
  inputs,
  ...
}: {
  i18n = {
    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5 = {
        waylandFrontend = true;
        addons = with pkgs; [
          fcitx5-mozc-ut
          fcitx5-gtk
          qt6Packages.fcitx5-configtool
        ];
      };
    };
  };

  environment.variables = {
    QT_IM_MODULE = "fcitx"; #managed by fcitx5
    XMODIFIERS = "@im=fcitx";
  };
}
