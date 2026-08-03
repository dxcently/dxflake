{
  lib,
  callPackage,
  runCommand,
  makeWrapper,
  python313,
  ripgrep,
  pyproject-nix,
  uv2nix,
  pyproject-build-systems,
}:

# kimi-cli: Moonshot's official CLI coding agent. Not in nixpkgs (a ~30-package
# Python app with exact pins), so we build it from its own uv.lock via uv2nix.
#
# BUMPING THIS: bump the pin in pyproject.toml, then regenerate the lock
#   (`nix run nixpkgs#uv -- lock` in this dir). uv2nix reads uv.lock; no hashes
#   to hand-edit. If a dep gains a build-from-sdist step that lacks a backend,
#   add a fixup to `pyprojectOverrides` below.
let
  python = python313;

  workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

  # Prefer wheels: most deps ship py3-none-any wheels, so almost nothing needs a
  # local build backend. The few sdist-only deps fall back automatically.
  overlay = workspace.mkPyprojectOverlay { sourcePreference = "wheel"; };

  # Build-system fixups for sdist-only deps that don't declare their backend.
  # ripgrepy ships no wheel and forgets to list setuptools in build-system.
  pyprojectOverrides = final: prev: {
    ripgrepy = prev.ripgrepy.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ final.resolveBuildSystem { setuptools = [ ]; };
    });
  };

  pythonSet = (callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
    lib.composeManyExtensions [
      pyproject-build-systems.overlays.default
      overlay
      pyprojectOverrides
    ]
  );

  # A venv holding kimi-cli + its full locked dependency closure.
  venv = pythonSet.mkVirtualEnv "kimi-cli-env" workspace.deps.default;
in
# Expose only the agent's entrypoints (not the venv's python/pip/etc), and put
# ripgrep on PATH — kimi-cli drives it through the `ripgrepy` binding.
runCommand "kimi-cli-1.49.0"
  {
    nativeBuildInputs = [ makeWrapper ];
    meta = {
      description = "Moonshot's Kimi CLI coding agent";
      homepage = "https://pypi.org/project/kimi-cli/";
      mainProgram = "kimi";
    };
  }
  ''
    mkdir -p $out/bin
    for b in kimi kimi-cli; do
      makeWrapper ${venv}/bin/$b $out/bin/$b \
        --prefix PATH : ${lib.makeBinPath [ ripgrep ]}
    done
  ''
