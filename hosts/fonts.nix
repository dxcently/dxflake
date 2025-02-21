{
  config,
  pkgs,
  ...
}: {
  fonts = {
    packages = with pkgs; [
      corefonts
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      noto-fonts-color-emoji
      material-icons
      font-awesome
      fira-code-symbols
      symbola
      nerd-fonts.jetbrains-mono
      nerd-fonts.comic-shanns-mono
      nerd-fonts.shure-tech-mono
      nerd-fonts.lekton
      (pkgs.callPackage ../packages/azukifontB/azukifontB.nix {})
      (pkgs.callPackage ../packages/azuki_font/azuki_font.nix {})
    ];
    fontconfig = {
      defaultFonts = {
        serif = ["azukifontB"];
        sansSerif = ["ComicShannsMono Nerd Font"];
        monospace = ["ComicShannsMono Nerd Font"];
      };
    };
  };
}
