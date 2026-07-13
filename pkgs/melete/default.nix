{
  stdenvNoCC,
  curl,
  cacert,
}:

# Pinned to this release's SHA256SUMS
# (github.com/noah427/melete releases/tag/canary-9d8de3c):
#   33c012ef9997ffe05ebaf7bd51b00e5d4b9e363afd35eb4dd8aa3c2aaf7d6cd0  melete-x86_64-unknown-linux-musl
let
  version = "canary-9d8de3c";

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
    outputHash = "sha256-M8AS75mX/+Beuve9UbAOXUueNjr9NetN2Ko8Kq99bNA=";

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
