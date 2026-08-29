{
  lib,
  config,
  pkgs,
  inputs,
  username,
  ...
}:
let
  # Built from the ~/melete dev checkout (the `melete-src` flake
  # input) — version and contents follow that repo. See flake.nix for how to
  # pick up a new commit or a dirty worktree.
  meletePkg = pkgs.callPackage ../../pkgs/melete-package.nix {
    src = inputs.melete-src;
  };
in
{
  options.dx.melete.enable = lib.mkEnableOption "Melete AI harness service";

  config = lib.mkIf config.dx.melete.enable {
    # --- Dev-checkout baseline, self-update floats above it ------------------
    # Nix builds the binary from ~/melete (pkgs/melete-package.nix).
    # We seed ~/.local/bin/melete from that store binary ONLY when the build
    # changes (tracked by a stamp file). Between builds the running binary is
    # left untouched, so anything that swapped it in place — melete's own
    # self-update, a hand-built `cargo build` — survives reboots. (On sakaki
    # self-update is off and managed_externally, so in practice this seed is
    # the only thing that moves it; see pkgs/melete-package.nix.)
    #
    # The stamp holds the STORE PATH, not the version: the dev repo's Cargo
    # version sits still across most commits, so a version stamp would leave
    # the box running yesterday's build after a rebuild that had already
    # compiled today's. The store path moves whenever the source does, which
    # is exactly the "follow the dev repo" contract.
    system.activationScripts.meleteSeed = {
      deps = [ "users" ];
      text = ''
        bindir="/home/${username}/.local/bin"
        bin="$bindir/melete"
        stamp="$bindir/.melete-pinned"
        want="${meletePkg}"
        if [ "$(cat "$stamp" 2>/dev/null)" != "$want" ] || [ ! -e "$bin" ]; then
          install -Dm755 ${meletePkg}/bin/melete "$bin"
          printf '%s' "$want" > "$stamp"
          chown -R ${username}:users "$bindir"
        fi
      '';
    };

    # Building from the dev checkout retired a whole apparatus that used to
    # live here: a sops-rendered `impure-env = NIX_GITHUB_RELEASE_TOKEN=<token>`
    # !included into nix.conf, so the release-asset fixed-output derivation
    # could authenticate to the private repo. With it went its cold-host
    # catch-22 (activation needed the token that only a successful activation
    # installs), the nix-daemon-reads-nix.conf-once trap, and the pre-seed
    # workaround for both. A local source build needs no credential at all.
    #
    # secrets/github-release-token.yaml is left on disk but is now
    # unreferenced. `git show 99c7c55:modules/dendrites/melete.nix` has the
    # full wiring and its debugging notes if a release-fetch build is ever
    # wanted back.

    # ~/.local/bin is only in ~/.profile (login shells); add it to bashrc so
    # Hyprland terminal emulators (non-login) pick it up too.
    home-manager.users.${username}.programs.bash.bashrcExtra = ''
      export PATH="$HOME/.local/bin:$PATH"
    '';

    # Allow khoa to restart melete.service without auth — needed for the
    # self-update swap (renames new binary into place, then restarts itself).
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id === "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") === "melete.service" &&
            subject.user === "${username}") {
          return polkit.Result.YES;
        }
      });
    '';

    # Binary and config are deployed out-of-band to ~/.config/melete/.
    # The Condition guards against crash-looping on a host where deployment
    # hasn't happened yet.
    systemd.services.melete = {
      description = "Melete — Mneme's companion AI harness";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      # Default StartLimitBurst=5/IntervalSec=10s means 5 early crashes (a
      # rough post-outage boot, self-update mid-swap, etc.) permanently fail
      # the unit -- Restart=on-failure then stops retrying until someone runs
      # `systemctl reset-failed`. Disable the limit so it always keeps trying.
      unitConfig.StartLimitIntervalSec = 0;
      unitConfig.ConditionPathExists = [
        "/home/${username}/.local/bin/melete"
        "/home/${username}/.config/melete/config.toml"
      ];
      serviceConfig = {
        Type = "simple";
        User = username;
        Environment = [
          "HOME=/home/${username}"
          "PATH=/home/${username}/.local/bin:/home/${username}/.cargo/bin:/etc/profiles/per-user/${username}/bin:/run/current-system/sw/bin"
        ];
        EnvironmentFile = "-/home/${username}/.config/melete/melete.env";
        WorkingDirectory = "/home/${username}/Melete";
        ExecStart = "/home/${username}/.local/bin/melete --config /home/${username}/.config/melete/config.toml serve";
        Restart = "on-failure";
        RestartSec = 10;
        CPUWeight = 200;
        OOMScoreAdjust = -500;
        # -500 exempts melete from the kernel's global OOM killer, so without
        # a cap of its own a runaway daemon drags the whole box into swap.
        MemoryHigh = "6G";
        MemoryMax = "8G";
        MemorySwapMax = "1G";
        TimeoutStopSec = "16min";
      };
    };
  };
}
