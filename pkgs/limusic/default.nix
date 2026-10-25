# Limusic, a Tauri YouTube Music client. Not in nixpkgs; upstream's flake is a
# dev shell only. Built from the release .deb against nixpkgs' webkitgtk rather
# than the AppImage, which bundles its own. Bump: change `version`, then set
# `hash` from `nix hash file` on the new .deb. The app's own updater cannot
# write the store, so this is the only way it updates.
{
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook3,
  webkitgtk_4_1,
  gtk3,
  mpv-unwrapped,
  libayatana-appindicator,
  glib-networking,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "limusic";
  version = "1.3.0";

  src = fetchurl {
    url = "https://github.com/SimoHypers/limusic/releases/download/v${finalAttrs.version}/limusic_${finalAttrs.version}_amd64.deb";
    hash = "sha256-45OFJCvFTYc7zm7EDuL2iUtU6gytcmjRrOHaSAoVenc=";
  };

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook3
  ];
  buildInputs = [
    webkitgtk_4_1
    gtk3
    mpv-unwrapped
    glib-networking
  ];
  # dlopened at runtime, so autoPatchelf cannot see them as NEEDED.
  runtimeDependencies = [
    libayatana-appindicator
    mpv-unwrapped
  ];

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out/
    runHook postInstall
  '';
})
