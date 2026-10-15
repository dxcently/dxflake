{ stdenvNoCC }:

# Sleet VGA v8.8, the snowglobe pixel face (OFL 1.1, Copyright 2026 dxcently).
# Built in the snowglobe font workspace; the TTFs here are that build's output.
stdenvNoCC.mkDerivation {
  name = "sleet-vga-8.8";
  src = ./.;

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out/share/fonts/truetype/sleet-vga *.ttf
    install -Dm644 OFL.txt $out/share/licenses/sleet-vga/OFL.txt

    runHook postInstall
  '';
}
