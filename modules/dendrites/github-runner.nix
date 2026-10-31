# modules/dendrites/github-runner.nix — the self-hosted Actions runner Aoide's CI
# runs `nix flake check` on. One runner, for the one repo, on the host that
# selects it.
#
# The repo is public, and a workflow file is code a fork's pull request can
# rewrite, so "pushes only" cannot rest on the workflow's own triggers. The
# job-started hook below runs on the runner before any step of any job and
# fails the job unless it is a push or a by-hand run of this repo. The runner
# carries only its own label (no `self-hosted`, no `linux`), so a workflow
# reaches it only by naming that label.
#
# The registration token comes from sops (secrets/github-runner.yaml, key
# `github-runner/aoide-token`), readable by root alone.
{
  config,
  pkgs,
  ...
}:
let
  repo = "dxcently/Aoide";
  pushesOnly = pkgs.writeShellScript "aoide-runner-pushes-only" ''
    case "$GITHUB_EVENT_NAME" in
      push | workflow_dispatch) ;;
      *)
        echo "this runner serves pushes and by-hand runs only, not '$GITHUB_EVENT_NAME'" >&2
        exit 1
        ;;
    esac
    if [ "$GITHUB_REPOSITORY" != ${repo} ]; then
      echo "this runner serves ${repo} only, not '$GITHUB_REPOSITORY'" >&2
      exit 1
    fi
  '';
in
{
  services.github-runners.aoide = {
    enable = true;
    url = "https://github.com/${repo}";
    tokenFile = config.sops.secrets."github-runner/aoide-token".path;
    name = config.networking.hostName;
    noDefaultLabels = true;
    extraLabels = [ "aoide-${config.networking.hostName}" ];
    replace = true;
    extraPackages = [
      pkgs.nix
      pkgs.git
    ];
    extraEnvironment.ACTIONS_RUNNER_HOOK_JOB_STARTED = toString pushesOnly;
  };

  sops.secrets."github-runner/aoide-token".sopsFile = ../../secrets/github-runner.yaml;
}
