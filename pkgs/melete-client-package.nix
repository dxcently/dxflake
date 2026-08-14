{
  stdenvNoCC,
  curl,
  jq,
  cacert,
  version,
  repo,
  target,
  sha256,
}:

# Generic Melete client package — fetch the release binary from the GitHub
# Release on the (private) upstream repo and install it. Bump by passing
# version/target/sha256 at the call site (see modules/dendrites/melete.nix).
#
# RELEASE SCHEME: one v* tag series (v0.3.4, ...); each tag's GitHub Release
# carries the musl binary as an asset. The fetch goes through the API assets
# endpoint — the browser URL (github.com/.../releases/download/...) 404s for
# private repos even with a token, while
#   api.github.com/repos/<repo>/releases/assets/<id>
# with `Accept: application/octet-stream` serves the bytes. The asset id is
# resolved from the tag at fetch time, so only version+sha256 are pinned.
#
# VERIFYING A BUMP: the hash is a fixed-output hash of the fetched binary.
# Download it by hand first and compare (must match exactly):
#   gh release download v<version> --repo <owner>/<repo> \
#     -p "<target>" -D /tmp --clobber
#   nix hash convert --hash-algo sha256 --to sri \
#     "$(sha256sum /tmp/<target> | cut -d' ' -f1)"
# If the rebuild then fails with `curl: (22) ... 404`, do NOT assume the token
# is dead: the likely cause is that the host's RUNNING generation predates the
# impure-env wiring in modules/dendrites/melete.nix (see the COLD-HOST
# CATCH-22 comment there) — pre-seed the store instead. Note --add-fixed names
# the store path after the FILE, so the temp file must be named exactly
# melete-bin-v<version> or the FOD will not match it.

# Fixed-output fetch via our OWN curl call, not fetchurl. fetchurl passes
# curlOptsList as a quoted bash array ("${curlOptsList[@]}"), so a literal
# $NIX_GITHUB_RELEASE_TOKEN inside a header is never expanded — and the
# header's space breaks the unquoted curlOpts/NIX_CURL_FLAGS paths too. Here
# the header is expanded by our shell, so the Bearer token lands intact. The
# token comes from the nix-daemon's environment via __impureEnvVars and,
# because the output hash is fixed, never affects the result.
let
  bin = stdenvNoCC.mkDerivation {
    name = "melete-bin-v${version}";

    nativeBuildInputs = [
      curl
      jq
    ];

    outputHashMode = "flat";
    outputHashAlgo = "sha256";
    outputHash = sha256;

    __impureEnvVars = [ "NIX_GITHUB_RELEASE_TOKEN" ];
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    buildCommand = ''
      auth=(-H "Authorization: Bearer $NIX_GITHUB_RELEASE_TOKEN")
      asset_id=$(
        curl --fail --location --retry 3 --retry-connrefused \
          "''${auth[@]}" -H "Accept: application/vnd.github+json" \
          "https://api.github.com/repos/${repo}/releases/tags/v${version}" \
        | jq -r --arg t "${target}" '.assets[] | select(.name == $t) | .id'
      )
      if [ -z "$asset_id" ]; then
        echo "no asset named ${target} on ${repo} tag v${version}" >&2
        exit 1
      fi
      curl --fail --location --retry 3 --retry-connrefused \
        "''${auth[@]}" -H "Accept: application/octet-stream" \
        -o "$out" \
        "https://api.github.com/repos/${repo}/releases/assets/$asset_id"
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
    description = "Melete agent binary (v${version}), fetched from the GitHub Release";
    mainProgram = "melete";
  };
}
