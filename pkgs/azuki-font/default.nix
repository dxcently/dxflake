{ stdenv, fetchzip }:

stdenv.mkDerivation {
  name = "azuki_font";

  src = fetchzip {
    # azukifont.com stopped resolving (2026-09); the Wayback copy is the same
    # zip, so the fixed-output hash — and the font — are unchanged.
    urls = [
      "http://azukifont.com/font/azukifont121.zip"
      "https://web.archive.org/web/20201102032925id_/http://azukifont.com/font/azukifont121.zip"
    ];
    sha256 = "sha256-mw2dgvzAX9k2vEmuHtH3enAl3Zs7aLdUcWEczdaaxrw=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/azuki
    install *.ttf $out/share/fonts/azuki

    runHook postInstall
  '';
}
