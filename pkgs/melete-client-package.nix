{
  stdenvNoCC,
  curl,
  cacert,
  version,
  target,
  sha256,
}:

# Generic Melete client package — fetch the release binary from the
# distributor and install it. Bump by passing version/target/sha256 at the
# call site (see modules/dendrites/melete.nix).
#
# RELEASE SCHEME: one v* tag series (v0.2.0, ...) with canary/stable channel
# pointers — the distributor URL is
#   https://melete-distributor.rdct.dev/artifacts/v<version>/<target>
# The `v` prefix is part of the path even though `version` is passed bare.
#
# VERIFYING A BUMP: the hash is a fixed-output hash of the fetched binary.
# Download it by hand first and compare (must match exactly):
#   TOK=$(sudo sed -E 's/.*NIX_MELETE_READ_TOKEN=//' \
#     /run/secrets/rendered/melete-impure-env.conf)
#   curl -sI -H "Authorization: Bearer $TOK" \
#     https://melete-distributor.rdct.dev/artifacts/v<version>/<target>
#   200 => artifact exists. Then:
#   curl -fL -H "Authorization: Bearer $TOK" -o /tmp/melete-bin-v<version> \
#     https://melete-distributor.rdct.dev/artifacts/v<version>/<target>
#   nix hash convert --hash-algo sha256 --to sri \
#     "$(sha256sum /tmp/melete-bin-v<version> | cut -d' ' -f1)"
# If the rebuild then fails with `curl: (22) ... error: 401`, do NOT assume
# the token is dead: the likely cause is that the host's RUNNING generation
# predates the impure-env wiring in modules/dendrites/melete.nix (see the
# COLD-HOST CATCH-22 comment there) — pre-seed the store instead. Note
# --add-fixed names the store path after the FILE, so the temp file must be
# named exactly melete-bin-v<version> or the FOD will not match it.

# Fixed-output fetch via our OWN curl call, not fetchurl. fetchurl passes
# curlOptsList as a quoted bash array ("${curlOptsList[@]}"), so a literal
# $NIX_MELETE_READ_TOKEN inside a header is never expanded — and the header's
# space breaks the unquoted curlOpts/NIX_CURL_FLAGS paths too. Here the header
# is expanded by our shell, so the Bearer token lands intact. The token comes
# from the nix-daemon's environment via __impureEnvVars and, because the
# output hash is fixed, never affects the result.
let
  bin = stdenvNoCC.mkDerivation {
    name = "melete-bin-v${version}";

    nativeBuildInputs = [ curl ];

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = sha256;

    __impureEnvVars = [ "NIX_MELETE_READ_TOKEN" ];
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    buildCommand = ''
      curl --fail --location --retry 3 --retry-connrefused \
        -H "Authorization: Bearer $NIX_MELETE_READ_TOKEN" \
        -o "$out" \
        "https://melete-distributor.rdct.dev/artifacts/v${version}/${target}"
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
    description = "Melete agent binary (v${version}), fetched via melete-distributor";
    mainProgram = "melete";
  };
}
