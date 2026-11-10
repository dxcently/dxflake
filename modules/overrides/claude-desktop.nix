# Ahead of the packaging flake: the desktop app pins the Code tab's CLI, so its
# version is what decides which models that tab can run.
{
  dendrites = [ "claude-desktop" ];
  overlay = final: prev: {
    claude-desktop = prev.claude-desktop.overrideAttrs (old: {
      version = "4.23118.1";
      src = final.fetchurl {
        url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_4.23118.1_amd64.deb";
        hash = "sha256-sJzN1ys4kWyWN9SFSNtw53xCXrLgm7RnRlQJ0v+dKHo=";
      };
      buildInputs = old.buildInputs ++ [ final.pipewire ];
    });
  };
}
