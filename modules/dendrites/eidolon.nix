# eidolon — the interactive Rust coding harness (github.com/noah427/eidolon),
# installed from its OWN flake (the `eidolon` input — see flake.nix). The CLI is
# a package on PATH. The plugins it loads (github.com/dxcently/eidolon-plugins)
# are declared in its config.toml, and the three daemons among them are user
# units here.
{
  pkgs,
  lib,
  inputs,
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
  # The CLI is not a service: Eidolon is an interactive terminal harness, so
  # it is a package on PATH. Its plugins' daemons are user units below.
  # The dev worktree at ~/eidolon is for editing it, and never what this installs.
  eidolonPkg = inputs.eidolon.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # The plugin flake. Its packages run the daemons, and its `rev` is the ref
  # every plugin is declared at: the directory `eidolon plugins sync` installs
  # and the binaries below come from one commit.
  plugins = inputs.eidolon-plugins.packages.${pkgs.stdenv.hostPlatform.system};
  pluginRef = inputs.eidolon-plugins.rev;

  # Eidolon reads this file and never writes one back, so Nix owns it. It carries
  # the defaults a missing file would also get, and the [plugins.*] declarations
  # that `eidolon plugins sync` reconciles against.
  #
  # Only config.toml is managed. secrets/, policy.rn, ui.rn and tools/ are
  # seeded and rewritten by Eidolon itself and must stay writable.
  #
  # The ollama key is deliberately absent: it lives in Eidolon's custodied
  # store (`eidolon secret set ollama`), which the built-in provider names as
  # `token_secret = "ollama"`. Same reasoning that retired melete.nix's sops
  # apparatus — these tools hold their own credentials.
  configToml = pkgs.writeText "eidolon-config.toml" ''
    default_model = "ollama:deepseek-v4.1-flash"
    default_persona = "Rook ♜"

    # Both MCP servers bind loopback on sakaki (mneme :8000, melete :8787);
    # the user unit eidolon-mcp-forward.service forwards them onto this host's
    # loopback. Passphrases the harness exchanges for a bearer token.
    [mneme]
    mcp_url = "http://127.0.0.1:8000/mcp"
    passphrase_file = "~/.config/eidolon/mneme-password"

    [melete]
    mcp_url = "http://127.0.0.1:8787/mcp"
    passphrase_file = "~/.config/eidolon/melete-password"

    [plugins.browser]
    repo = "dxcently/eidolon-plugins"
    ref = "${pluginRef}"
    trust = true
    grants = [ "file:~/.config/eidolon/browser.token" ]

    [plugins.subagent]
    repo = "dxcently/eidolon-plugins"
    ref = "${pluginRef}"
    trust = true

    [plugins.claude]
    repo = "dxcently/eidolon-plugins"
    ref = "${pluginRef}"

    [plugins.coordinator]
    repo = "dxcently/eidolon-plugins"
    ref = "${pluginRef}"
    trust = true
    grants = [ "file:~/.config/eidolon/coordinator.token" ]

    [plugins.hyprland]
    repo = "dxcently/eidolon-plugins"
    ref = "${pluginRef}"
    trust = true
  '';
in
{
  config = {
    environment.systemPackages = [ eidolonPkg ];

    habit.home = {
      xdg.configFile."eidolon/config.toml".source = configToml;

      # grim, wlrctl and wtype: the hyprland plugin's verbs run them from PATH.
      home.packages = [ plugins.hyprland ];

      systemd.user.services = {
        eidolon-plugins-sync = {
          Unit = {
            Description = "Install, update and trust eidolon plugins to match config.toml";
            # A switch that changes the declarations restarts this oneshot.
            X-Restart-Triggers = [ "${configToml}" ];
          };
          Service = {
            Type = "oneshot";
            # Stays active after exiting, so a switch sees it as running and
            # restarts it when X-Restart-Triggers changes.
            RemainAfterExit = true;
            ExecStart = "${eidolonPkg}/bin/eidolon plugins sync";
            Environment = [ "PATH=${lib.makeBinPath [ pkgs.git pkgs.openssh ]}" ];
            # A failed sync (no network yet, a clone that fails) retries.
            Restart = "on-failure";
            RestartSec = "30s";
          };
          Install.WantedBy = [ "default.target" ];
        };

        eidolon-browser = {
          Unit = {
            Description = "eidolon browser plugin daemon";
            After = [ "eidolon-plugins-sync.service" ];
          };
          Service = {
            ExecStart = lib.getExe' plugins.browser "eidolon-browser";
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };

        eidolon-coordinator = {
          Unit = {
            Description = "eidolon coordinator plugin daemon";
            After = [ "eidolon-plugins-sync.service" ];
          };
          Service = {
            ExecStart = lib.getExe' plugins.coordinator "eidolon-coordinator";
            Environment = [ "EIDOLON_COORDINATOR_BIN=${eidolonPkg}/bin/eidolon" ];
            Restart = "on-failure";
          };
          Install.WantedBy = [ "default.target" ];
        };
      };
    };
  };
}
