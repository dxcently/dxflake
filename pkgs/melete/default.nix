{
  stdenvNoCC,
  curl,
  cacert,
}:

# Pinned to this release's SHA256SUMS
# (github.com/noah427/melete releases/tag/0.2.0):
#   dfee72235c50b5ae5defe880e666c3ad5fd6835e15413db51a1daa03ded4ca25  melete-x86_64-unknown-linux-musl
# BUMPING THIS: if the rebuild fails with `curl: (22) ... error: 401`, do NOT
# assume the token is dead or the release is unpublished. The likely cause is
# that this host's RUNNING generation predates the impure-env wiring in
# modules/dendrites/melete.nix, so the daemon never had the token to give.
# Test the token directly before touching sops or asking the dev:
#   TOK=$(sudo sed -E 's/.*NIX_MELETE_READ_TOKEN=//' \
#     /run/secrets/rendered/melete-impure-env.conf)
#   curl -sI -H "Authorization: Bearer $TOK" \
#     https://melete-distributor.rdct.dev/artifacts/<version>/melete-x86_64-unknown-linux-musl
# 200 => token is fine, the host is unwired; pre-seed the store (see the
# COLD-HOST CATCH-22 comment in modules/dendrites/melete.nix). Note --add-fixed
# names the store path after the FILE, so the temp file must be named exactly
# melete-bin-<version> or the FOD will not match it and the fetch runs anyway.
let
  version = "0.2.0";

  # Fixed-output fetch via our OWN curl call, not fetchurl. fetchurl passes
  # curlOptsList as a quoted bash array ("${curlOptsList[@]}"), so a literal
  # $NIX_MELETE_READ_TOKEN inside a header is never expanded — and the header's
  # space breaks the unquoted curlOpts/NIX_CURL_FLAGS paths too. Here the header
  # is expanded by our shell, so the Bearer token lands intact. The token comes
  # from the nix-daemon's environment via __impureEnvVars and, because the
  # output hash is fixed, never affects the result.
  bin = stdenvNoCC.mkDerivation {
    name = "melete-bin-${version}";

    nativeBuildInputs = [ curl ];

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = "sha256-3+5yI1xQta5d7+iA5mbDrV/Wg14VQT21Gh2qA97UyiU=";

    __impureEnvVars = [ "NIX_MELETE_READ_TOKEN" ];
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    buildCommand = ''
      curl --fail --location --retry 3 --retry-connrefused \
        -H "Authorization: Bearer $NIX_MELETE_READ_TOKEN" \
        -o "$out" \
        "https://melete-distributor.rdct.dev/artifacts/${version}/melete-x86_64-unknown-linux-musl"
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "melete";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${bin} $out/bin/melete
    runHook postInstall
  '';

  meta = {
    description = "Melete agent binary (${version}), fetched via melete-distributor";
    mainProgram = "melete";
  };
}
