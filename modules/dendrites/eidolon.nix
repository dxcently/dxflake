# eidolon — the interactive Rust coding harness (github.com/noah427/eidolon),
# built from its `eidolon-src` flake input by pkgs/eidolon-package.nix. The CLI
# is a package on PATH. The plugins it loads (github.com/dxcently/eidolon-plugins)
# are declared in its config.toml, and the daemons among them are user units
# here.
{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Built from the `eidolon-src` flake input (github.com/noah427/eidolon
  # master), never the dev worktree at ~/eidolon. See flake.nix for how to
  # pick up a new commit (`dxbump`).
  eidolonPkg = pkgs.callPackage ../../pkgs/eidolon-package.nix {
    src = inputs.eidolon-src;
  };

  # The CLI is not a service: Eidolon is an interactive terminal harness, so
  # it is a package on PATH. Its plugins' daemons are user units below.

  # The plugin flake. Its packages run the daemons, and its `rev` is the ref
  # every plugin is declared at: the directory `eidolon plugins sync` installs
  # and the binaries below come from one commit.
  plugins = inputs.eidolon-plugins.packages.${pkgs.stdenv.hostPlatform.system};
  pluginRef = inputs.eidolon-plugins.rev;
in
{
  config = {
    environment.systemPackages = [ eidolonPkg ];

    habit.home =
      { osConfig, ... }:
      let
        # A graphical session is what the browser and hyprland plugins drive.
        # These gates read the host's own written habit.* keys. A dendrite
        # selected only through an aggregation's membership reads as null here,
        # so each gate must stay host-written.
        # An unselected dendrite's enable is null, not false, so each fact is
        # compared rather than used as a boolean.
        graphical = osConfig.habit.aggregation.desktop.enable == true;
        claudeCode = osConfig.habit.dendrites.claude-code.enable == true;
        # Mneme and Melete run on sakaki, the one host that carries them; every
        # other host reaches them through the forward below.
        mcpLocal =
          osConfig.habit.dendrites.mneme.enable == true || osConfig.habit.dendrites.melete.enable == true;

        # Eidolon reads this file and never writes one back, so Nix owns it. It
        # carries the defaults a missing file would also get, and the [plugins.*]
        # declarations that `eidolon plugins sync` reconciles against.
        #
        # The librewolf bridge is the mirror of the browser plugin: it owns no
        # browser, and reads only the tab a person attaches by clicking, in
        # their own LibreWolf, for as long as that `activeTab` grant lasts. It
        # declares no service either — the process that has to run is the
        # native messaging host LibreWolf starts, so the wiring here is the
        # manifest that names it, below, and the profile that loads the
        # extension. The extension itself is an operator's act (about:debugging
        # → Load Temporary Add-on → the plugin's extension/manifest.json).
        #
        # Only config.toml is managed. secrets/, policy.rn, ui.rn and tools/ are
        # seeded and rewritten by Eidolon itself and must stay writable.
        #
        # The ollama key is deliberately absent: it lives in Eidolon's custodied
        # store (`eidolon secret set ollama`), which the built-in provider names as
        # `token_secret = "ollama"`. Same reasoning that retired melete.nix's sops
        # apparatus — these tools hold their own credentials.
        browserPlugin = lib.optionalString graphical ''
          [plugins.browser]
          repo = "dxcently/eidolon-plugins"
          ref = "${pluginRef}"
          trust = true
          grants = [ "file:~/.config/eidolon/browser.token" ]

        '';
        hyprlandPlugin = lib.optionalString graphical ''

          [plugins.hyprland]
          repo = "dxcently/eidolon-plugins"
          ref = "${pluginRef}"
          trust = true
        '';
        # Host-written, not aggregation-selected, for the reason the gates above
        # give: an unselected dendrite's enable is null, and this one has to be
        # true on a host that selects it by name. Every host that runs the
        # bridge also has to run LibreWolf, so the host's own selection is the
        # only fact that decides it.
        librewolfSelected = osConfig.habit.dendrites.librewolf.enable == true;
        librewolfPlugin = lib.optionalString librewolfSelected ''

          [plugins.librewolf]
          repo = "dxcently/eidolon-plugins"
          ref = "${pluginRef}"
          trust = true
          grants = [ "file:~/.config/eidolon/librewolf.token" ]
        '';
        # LibreWolf starts this when the extension asks for it, so the manifest
        # has to sit where a Firefox-family browser looks and its `path` has to
        # be absolute. The binary prints its own manifest, which is the one
        # place the host name and the extension id are written down; asking it
        # at build time keeps this file from restating them.
        librewolfHostManifest = pkgs.runCommand "eidolon_librewolf.json" { } ''
          ${lib.getExe' plugins.librewolf "eidolon-librewolf"} --print-host-manifest > "$out"
        '';
        # The browser half of the bridge: one local XPI, built from the plugin's
        # own source (the flake input IS the checkout) and force-installed by
        # policy, so the add-on is there on every start instead of being loaded
        # by hand each session. A package cannot simply drop it into a profile —
        # a browser ignores extensions it did not install itself — and LibreWolf
        # refuses a policy install that is unsigned: about:policies#errors reads
        # `Download failed - ERROR_SIGNSTATE_REQUIRED` for this exact XPI, which
        # is why the librewolf dendrite turns signature enforcement off.
        librewolfBridgeXpi =
          pkgs.runCommand "eidolon-librewolf-bridge.xpi"
            {
              nativeBuildInputs = [ pkgs.zip ];
            }
            ''
              mkdir -p ext
              cp -r ${inputs.eidolon-plugins.outPath}/librewolf/extension/. ext/
              cd ext
              zip -qr "$out" .
            '';
        # eidolon does not expand ~ or $XDG_RUNTIME_DIR in a [[driver]] socket, so
        # the path is literal. 1000 is khoa's uid on osaka and sakaki; the account
        # sets none, so this is the one place that assumes it.
        driverSocket = "/run/user/1000/eidolon-claude.sock";
        claudeDriver = lib.optionalString claudeCode ''

          # --real spawns the real CLI, and each turn spends that account's usage.
          [[driver]]
          backend = "claude-cli"
          socket  = "${driverSocket}"
          mode    = "registry"
          models  = ["claude-*"]
        '';

        configToml = pkgs.writeText "eidolon-config.toml" (
          ''
            default_model = "ollama:deepseek-v4.1-flash"
            default_persona = "Rook ♜"

            # Both MCP servers bind loopback on sakaki (mneme :8000, melete :8787).
            # Off sakaki, the user unit eidolon-mcp-forward.service forwards them
            # onto this host's loopback. Passphrases the harness exchanges for a
            # bearer token.
            [mneme]
            mcp_url = "http://127.0.0.1:8000/mcp"
            passphrase_file = "~/.config/eidolon/mneme-password"

            [melete]
            mcp_url = "http://127.0.0.1:8787/mcp"
            passphrase_file = "~/.config/eidolon/melete-password"

            ${browserPlugin}[plugins.subagent]
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

            # Shares the ollama provider's key from eidolon's secret store.
            [plugins.websearch]
            repo = "dxcently/eidolon-plugins"
            ref = "${pluginRef}"
            trust = true
            grants = [ "secret:ollama" ]
          ''
          + hyprlandPlugin
          + librewolfPlugin
          + claudeDriver
          + "\n"
        );
      in
      {
        xdg.configFile."eidolon/config.toml".source = configToml;

        # grim, wlrctl and wtype: the hyprland plugin's verbs run them from PATH.
        home.packages = lib.optional graphical plugins.hyprland;

        # Where a Firefox-family browser looks for a native messaging host on
        # Linux. A file, not a profile: ~/.librewolf is the browser's own, and a
        # manifest is the one thing in it Nix can state without stealing a file
        # the browser writes.
        home.file = lib.mkIf librewolfSelected {
          ".librewolf/native-messaging-hosts/eidolon_librewolf.json".source = librewolfHostManifest;
        };

        # One extension id, force-installed from that XPI; every other add-on is
        # left alone (the AMO ones arrive through the account sync).
        programs.librewolf = lib.mkIf librewolfSelected {
          policies.ExtensionSettings."librewolf-bridge@eidolon.local" = {
            installation_mode = "force_installed";
            install_url = "file://${librewolfBridgeXpi}";
          };
        };

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
              Environment = [
                "PATH=${
                  lib.makeBinPath [
                    pkgs.git
                    pkgs.openssh
                  ]
                }"
              ];
              # A failed sync (no network yet, a clone that fails) retries.
              Restart = "on-failure";
              RestartSec = "30s";
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
        }
        // lib.optionalAttrs graphical {
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
        }
        // lib.optionalAttrs claudeCode {
          eidolon-claude = {
            Unit = {
              Description = "eidolon claude driver host (runs turns on the real Claude CLI)";
              After = [ "eidolon-plugins-sync.service" ];
            };
            Service = {
              ExecStart = "${lib.getExe' plugins.claude "eidolon-claude"} --real --cli ${pkgs.claude-code}/bin/claude --socket %t/eidolon-claude.sock";
              Restart = "on-failure";
            };
            Install.WantedBy = [ "default.target" ];
          };
        }
        // lib.optionalAttrs (!mcpLocal) {
          eidolon-mcp-forward = {
            Unit = {
              Description = "SSH forward to sakaki for the Mneme and Melete MCP servers";
              Documentation = "file:%h/.config/eidolon/config.toml";
            };
            Service = {
              Type = "simple";
              # Both servers bind loopback on sakaki, so the harness reaches them
              # through this tunnel rather than the Cloudflare route. The target is
              # sakaki's LAN address: it is not in the current tailnet, and the old
              # name sakaki.tailc27b51.ts.net no longer resolves.
              ExecStart = "${pkgs.openssh}/bin/ssh -N -o BatchMode=yes -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -o ServerAliveCountMax=3 -L 8000:127.0.0.1:8000 -L 8787:127.0.0.1:8787 192.168.1.202";
              # A roaming laptop drops the route often; the forward is the whole point
              # of the unit, so it comes back on its own.
              Restart = "always";
              RestartSec = 5;
            };
            Install.WantedBy = [ "default.target" ];
          };
        };
      };
  };
}
