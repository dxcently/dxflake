# Ahead of the packaging flake: the desktop app pins the Code tab's CLI, so its
# version is what decides which models that tab can run.
{
  dendrites = [ "claude-desktop" ];
  overlay = final: prev: {
    claude-desktop = prev.claude-desktop.overrideAttrs (old: {
      version = "2.26454.2";
      src = final.fetchurl {
        url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_2.26454.2_amd64.deb";
        hash = "sha256-slGgIkqGNYdPM1mN+O2JUrQn+EgV7llYDMAi1r2yQw8=";
      };
      buildInputs = old.buildInputs ++ [ final.pipewire ];
    });
  };
}
