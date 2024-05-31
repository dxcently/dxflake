{ pkgs }:

pkgs.stdenv.mkDerivation {
  name = "azuki_font";
  src = pkgs.fetchurl {
    url = "http://azukifont.com/font/azukifont121.zip";
    sha256 = "03c3hv21x757wyp835g7p44mqhqjxzmimgcdd1b7fck93vi66qsd";
  };

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/share/fonts/azuki/azuki-font
    ${pkgs.unzip}/bin/unzip $src -d $out/
  '';
}
