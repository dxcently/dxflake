{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.dx.aggregations.desktop {
    fonts = {
      packages = with pkgs; [
        corefonts
        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji
        material-icons
        font-awesome
        fira-code-symbols
        symbola
        nerd-fonts.jetbrains-mono
        nerd-fonts.comic-shanns-mono
        nerd-fonts.shure-tech-mono
        nerd-fonts.lekton
        (pkgs.callPackage ./../../pkgs/azuki-font-b { })
        (pkgs.callPackage ./../../pkgs/azuki-font { })
      ];
    };
  };
}
