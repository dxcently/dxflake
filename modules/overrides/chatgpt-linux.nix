# Keep ChatGPT current without moving the rest of the Aoide input.
# Source and SHA-256: OpenAI's stable Debian amd64 Packages index.
# Remove once the pinned Aoide package carries this release or newer.
{
  dendrites = [ "openai" ];

  # Aoide introduces the package in a normal-order overlay. Run after it so
  # its collision guard sees only the original nixpkgs package set.
  nixos = { lib, ... }: {
    nixpkgs.overlays = lib.mkAfter [
      (final: prev: {
        chatgpt-linux = prev.chatgpt-linux.overrideAttrs (
          finalAttrs: _old: {
            version = "26.928.20755";
            src = final.fetchurl {
              url = "https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/chatgpt/chatgpt_${finalAttrs.version}_amd64.deb";
              hash = "sha256-RYbcGmyGmJgsqFn4aqoWg18zgyoJ4kBC36dVcapg2NE=";
            };
          }
        );
      })
    ];
  };
}
