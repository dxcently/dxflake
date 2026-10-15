{ lib, stdenvNoCC }:

# Sleet VGA, the snowglobe pixel face (OFL 1.1, Copyright 2026 dxcently).
# The files here come from ~/sleet-fonts/sleet-vga via its sync.sh; VERSION names the build.
stdenvNoCC.mkDerivation {
  pname = "sleet-vga";
  version = lib.fileContents ./VERSION;
  src = ./.;

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/share/fonts/truetype/sleet-vga *.ttf
    install -Dm644 OFL.txt $out/share/licenses/sleet-vga/OFL.txt

    runHook postInstall
  '';
}
