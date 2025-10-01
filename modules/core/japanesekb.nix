{
  pkgs,
  config,
  lib,
  ...
}: {
  options.mine.japaneseInput = lib.mkEnableOption "japanese input";

  config = lib.mkIf config.mine.japaneseInput {
    i18n.inputMethod = {
      enabled = "fcitx5";
      fcitx5.addons = [
        pkgs.fcitx5-mozc
      ];
    };

    environment.variables.GLFW_IM_MODULE = "ibus";

    mine.xUserConfig.xsession.initExtra = ''
      ${config.i18n.inputMethod.package}/bin/fcitx5 &
    '';
  };
}
