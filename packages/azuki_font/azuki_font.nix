{ stdenv, fetchzip }:

stdenv.mkDerivation {
  name = "azuki_font";

  src = fetchzip {
    url = "http://azukifont.com/font/azukifont121.zip";
    sha256 = "sha256-mw2dgvzAX9k2vEmuHtH3enAl3Zs7aLdUcWEczdaaxrw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/azuki
    install *.ttf $out/share/fonts/azuki

    runHook postInstall
  '';
}
