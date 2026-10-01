{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  installShellFiles,
  bubblewrap,
  ripgrep,
  ncurses,
  libcap,
  versionCheckHook,
}:
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "codex";
  version = "0.159.2";

  src = fetchurl {
    url = "https://registry.npmjs.org/@openai/codex/-/codex-${finalAttrs.version}-linux-x64.tgz";
    hash = "sha512-RrCZ1X52wpa1lOsXtCtSyhjOFdQPh7LH5Ccv8HsKmd/2UXbUwxXFqWXFK3JzatquUNGtW/TLox5Y7qVOGkV0/Q==";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    installShellFiles
  ];
  buildInputs = [
    ncurses
    libcap
  ];
  dontBuild = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/libexec/codex" "$out/bin"
    # Preserve the package manifest and sibling resources: the CLI discovers
    # code-mode, voice and shell helpers relative to its real executable.
    cp -a vendor/x86_64-unknown-linux-musl/. "$out/libexec/codex/"
    makeWrapper "$out/libexec/codex/bin/codex" "$out/bin/codex" \
      --prefix PATH : ${
        lib.makeBinPath [
          ripgrep
          bubblewrap
        ]
      }
    ln -s "$out/libexec/codex/bin/codex-code-mode-host" "$out/bin/codex-code-mode-host"
    installShellCompletion --cmd codex \
      --bash <($out/bin/codex completion bash) \
      --fish <($out/bin/codex completion fish) \
      --zsh <($out/bin/codex completion zsh)
    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  meta = {
    description = "OpenAI Codex CLI, official Linux release bundle";
    homepage = "https://github.com/openai/codex";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    mainProgram = "codex";
    platforms = [ "x86_64-linux" ];
  };
})
