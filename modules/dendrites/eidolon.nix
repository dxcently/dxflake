# eidolon — the interactive Rust coding harness (github.com/noah427/eidolon),
# installed from its OWN flake (the `eidolon` input — see flake.nix). System-only:
# a CLI/TUI a user runs from a terminal, not a service.
{
  nixos =
    {
      pkgs,
      inputs,
      username,
      ...
    }:
    let
      # Eidolon builds from its OWN flake (the `eidolon` input, pinned to
      # github.com/noah427/eidolon master — see flake.nix). That repo's
      # nix/eidolon.nix already reassembles the `../harnox` sibling layout its
      # Cargo `[patch]` table expects, and its flake.lock pins the harnox rev
      # matching the tag in its Cargo.toml, so there is nothing for dxflake to
      # package here. `nix flake update eidolon` is the whole upgrade path.
      #
      # Not a service: Eidolon is an interactive terminal harness, so this is a
      # package on PATH, not a systemd unit like melete.nix/mneme.nix. The dev
      # worktree at ~/eidolon is for editing it, and never what this installs.
      eidolonPkg = inputs.eidolon.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      config = {
        environment.systemPackages = [ eidolonPkg ];

        # Eidolon reads this file and never writes one back; AGENTS.md names Nix as
        # its expected generator on this host. Until noah427/eidolon#2 lands, the
        # file must simply EXIST: a missing config takes the derived `Default`,
        # which skips the `#[serde(default)]` fallbacks and leaves max_iterations
        # at 0, so every turn dies before reaching a provider.
        #
        # Only config.toml is managed. secrets/, policy.rn, ui.rn and tools/ are
        # seeded and rewritten by Eidolon itself and must stay writable.
        #
        # The ollama key is deliberately absent: it lives in Eidolon's custodied
        # store (`eidolon secret set ollama`), which the built-in provider names as
        # `token_secret = "ollama"`. Same reasoning that retired melete.nix's sops
        # apparatus — these tools hold their own credentials.
        home-manager.users.${username}.xdg.configFile."eidolon/config.toml".text = ''
          default_model = "ollama:deepseek-v4.1-flash"

          # The Claude Code CLI as a backend, reachable as claude-cli:<model>.
          # Billed to the existing subscription, not to the ollama key.
          [claude_cli]
          models = [ "claude-*", "sonnet", "opus", "haiku" ]
        '';
      };
    };
}
