{ stdenv, fetchzip }:
stdenv.mkDerivation {
  name = "azuki_fontB";

  src = fetchzip {
    url = "http://azukifont.com/font/azukifontB120.zip";
    sha256 = "sha256-pqlsqVuKcI1K/TowEd1qxNH/P5QoLrhvJNrUDHuX5ms=";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/azuki
    install *.ttf $out/share/fonts/azuki

    runHook postInstall
  '';
}
