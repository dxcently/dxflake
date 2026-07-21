{
  stdenvNoCC,
  curl,
  cacert,
}:

# Pinned to this release's SHA256SUMS
# (github.com/noah427/melete releases/tag/canary-efc05e7):
#   08dbed6f32a1e28ab8dba2c0d7120ae4f76148bb548f913d4a1031e3e8df8183  melete-x86_64-unknown-linux-musl
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
  version = "canary-efc05e7";

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
    outputHash = "sha256-CNvtbzKh4oq426LA1xIK5PdhSLtUj5E9ShAx4+jfgYM=";

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
