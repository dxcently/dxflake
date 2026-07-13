{ stdenvNoCC, fetchurl }:

# Pinned to this release's SHA256SUMS
# (github.com/noah427/melete releases/tag/canary-9d8de3c):
#   33c012ef9997ffe05ebaf7bd51b00e5d4b9e363afd35eb4dd8aa3c2aaf7d6cd0  melete-x86_64-unknown-linux-musl
stdenvNoCC.mkDerivation rec {
  pname = "melete";
  version = "canary-9d8de3c";

  src = fetchurl {
    url = "https://melete-distributor.rdct.dev/artifacts/${version}/melete-x86_64-unknown-linux-musl";
    sha256 = "sha256-M8AS75mX/+Beuve9UbAOXUueNjr9NetN2Ko8Kq99bNA=";
    # Authenticated fixed-output fetch — the bearer token comes from the
    # *builder's* (nix-daemon's) environment via __impureEnvVars below, so it's
    # never baked into the derivation and doesn't affect the output hash.
    curlOptsList = [
      "-H"
      "Authorization: Bearer $NIX_MELETE_READ_TOKEN"
    ];
  };

  __impureEnvVars = [ "NIX_MELETE_READ_TOKEN" ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = "install -Dm755 $src $out/bin/melete";

  meta = {
    description = "Melete agent binary (${version}), fetched via melete-distributor";
    mainProgram = "melete";
  };
}
