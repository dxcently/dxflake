{username, ...}: {
  # direnv on every host: a repo carrying `.envrc` (`use flake`) loads its
  # dev shell on `cd` and unloads on leave. nix-direnv caches the evaluated
  # shell so re-entering a directory doesn't re-run `nix develop`.
  # Ungated on purpose — same as starship/git: it's a shell convenience, not
  # a role. First use per repo still needs `direnv allow`.
  home-manager.users.${username} = {
    programs.direnv = {
      enable = true;
      enableBashIntegration = true;
      nix-direnv.enable = true;
      # keep the "direnv: export +FOO +BAR" spam off the prompt
      config.global.hide_env_diff = true;
    };
  };
}
