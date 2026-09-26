{ stdenv, fetchzip }:
stdenv.mkDerivation {
  name = "azukifontB";

  src = fetchzip {
    # azukifont.com stopped resolving (2026-09); the Wayback copy is the same
    # zip, so the fixed-output hash — and the font — are unchanged.
    urls = [
      "http://azukifont.com/font/azukifontB120.zip"
      "https://web.archive.org/web/20211021012306id_/http://azukifont.com/font/azukifontB120.zip"
    ];
    sha256 = "sha256-pqlsqVuKcI1K/TowEd1qxNH/P5QoLrhvJNrUDHuX5ms=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/azuki
    install *.ttf $out/share/fonts/azuki

    runHook postInstall
  '';
}
