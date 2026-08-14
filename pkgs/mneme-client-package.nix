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

# Generic Mneme client package — fetch the release binary from the GitHub
# Release on the (private) upstream repo and install it. Bump by passing
# version/target/sha256 at the call site (see modules/dendrites/mneme.nix).
#
# Deliberately reuses melete's token wiring instead of standing up a parallel
# one: same GitHub release-asset fetch, same NIX_GITHUB_RELEASE_TOKEN, just a
# different repo + asset. See pkgs/melete-client-package.nix for the RELEASE
# SCHEME / VERIFYING A BUMP notes and modules/dendrites/melete.nix for the
# COLD-HOST CATCH-22 — both apply here unchanged, since it's the same
# FOD-via-our-own-curl shape for the same reason (fetchurl can't get the
# Bearer header through intact).
#
# Consequence of reusing the token: this derivation only builds while
# dx.melete.enable is ALSO true on the host (that's where the sops secret +
# impure-env wiring actually live). If mneme ever needs to run on a host
# without melete, this needs its own token plumbing first.
let
  bin = stdenvNoCC.mkDerivation {
    name = "mneme-bin-v${version}";

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
  pname = "mneme";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 ${bin} $out/bin/mneme
    runHook postInstall
  '';

  meta = {
    description = "Mneme vault MCP server binary (v${version}), fetched from the GitHub Release";
    mainProgram = "mneme";
  };
}
