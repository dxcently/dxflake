{
  stdenvNoCC,
  curl,
  cacert,
  version,
  target,
  sha256,
}:

# Generic Mneme client package — fetch the release binary from the
# distributor and install it. Bump by passing version/target/sha256 at the
# call site (see modules/dendrites/mneme.nix).
#
# Deliberately reuses melete's distributor + token wiring instead of standing
# up a parallel one: same host (melete-distributor.rdct.dev), same
# NIX_MELETE_READ_TOKEN, just a different artifact target. See
# pkgs/melete-client-package.nix for the RELEASE SCHEME / VERIFYING A BUMP
# notes and modules/dendrites/melete.nix for the COLD-HOST CATCH-22 — both
# apply here unchanged, since it's the same FOD-via-our-own-curl shape for
# the same reason (fetchurl can't get the Bearer header through intact).
#
# Consequence of reusing the token: this derivation only builds while
# dx.melete.enable is ALSO true on the host (that's where the sops secret +
# impure-env wiring actually live). If mneme ever needs to run on a host
# without melete, this needs its own token plumbing first.
let
  bin = stdenvNoCC.mkDerivation {
    name = "mneme-bin-v${version}";

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
    description = "Mneme vault MCP server binary (v${version}), fetched via melete-distributor";
    mainProgram = "mneme";
  };
}
