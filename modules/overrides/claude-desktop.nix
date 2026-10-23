# Ahead of the packaging flake: the desktop app pins the Code tab's CLI, so its
# version is what decides which models that tab can run.
{
  dendrites = [ "claude-desktop" ];
  overlay = final: prev: {
    claude-desktop = prev.claude-desktop.overrideAttrs (old: {
      version = "3.6556.1";
      src = final.fetchurl {
        url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_3.6556.1_amd64.deb";
        hash = "sha256-ztUXmZf9uQIZ6GZoXH87z8tJRRTYICLifImyijcd/oc=";
      };
      buildInputs = old.buildInputs ++ [ final.pipewire ];
    });
  };
}
