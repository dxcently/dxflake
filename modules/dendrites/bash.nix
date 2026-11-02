{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.bash ];

  habit.home =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [
        lsd
        # The first-party inputs move fast; `dxupdate` re-locks EVERYTHING
        # (nixpkgs, home-manager, Aoide's own inputs, ...), a world rebuild for
        # what is usually a one-repo change. dxbump re-locks only these (or the
        # inputs named as arguments), builds every host here so sakaki's bumps
        # are proved on osaka, and pushes the lock only if all of them built.
        # comin then carries it to every host; a lock that is never pushed would
        # be undone at the next comin deploy.
        (writeShellApplication {
          name = "dxbump";
          runtimeInputs = [ jq ];
          text = ''
            cd /home/khoa/dxflake
            if [ "$#" -gt 0 ]; then
              inputs=("$@")
            else
              inputs=(melete-src mneme-src eidolon-src eidolon-plugins aoide snowglobe)
            fi
            if ! git diff --quiet HEAD; then
              echo "dxbump: uncommitted changes in dxflake; commit or stash them first" >&2
              exit 1
            fi
            git pull --ff-only
            nix flake update "''${inputs[@]}"
            if git diff --quiet flake.lock; then
              echo "dxbump: already current"
              exit 0
            fi
            names=$(nix eval --raw .#nixosConfigurations --apply 'c: builtins.concatStringsSep " " (builtins.attrNames c)')
            read -ra hosts <<<"$names"
            targets=()
            for h in "''${hosts[@]}"; do
              targets+=(".#nixosConfigurations.$h.config.system.build.toplevel")
            done
            if ! nix build --no-link "''${targets[@]}"; then
              git checkout flake.lock
              echo "dxbump: a host failed to build; flake.lock restored, nothing pushed" >&2
              exit 1
            fi
            moved=""
            for i in "''${inputs[@]}"; do
              rev() { jq -r --arg i "$i" '.nodes[.nodes.root.inputs[$i]].locked.rev[0:8]'; }
              new=$(rev <flake.lock)
              if [ "$(git show HEAD:flake.lock | rev)" != "$new" ]; then
                moved="''${moved:+$moved, }$i $new"
              fi
            done
            git commit -m "flake.lock: $moved" flake.lock
            git push
            nh os switch /home/khoa/dxflake/
          '';
        })
      ];
      programs.bash = {
        enable = true;
        enableCompletion = true;
        profileExtra = ''
          if [ "$(tty)" = "/dev/tty1" ] && command -v Hyprland >/dev/null; then
            exec Hyprland &> /dev/null
          fi
        '';
        initExtra = ''
          command -v fastfetch >/dev/null && fastfetch
        '';
        bashrcExtra = ''
          command -v mcfly >/dev/null && eval "$(mcfly init bash)"

          # github: tarball fetches count against GitHub's API rate limit
          # unless nix holds a token; hand it the gh login. The private repos
          # are git+https and use git's credential helper instead.
          t=$(gh auth token 2>/dev/null) && export NIX_CONFIG="access-tokens = github.com=$t"
          unset t

          function y() {
          local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
          yazi "$@" --cwd-file="$tmp"
          if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          	builtin cd -- "$cwd"
          fi
          rm -f -- "$tmp"
             }
        '';
        sessionVariables = {
          khoa = "true";
        };
        shellAliases = {
          v = "nvim";
          nv = "nvim";
          dx = "cd /home/khoa/dxflake";
          dxrebuild = "nh os switch /home/khoa/dxflake/";
          dxupdate = "nh os switch /home/khoa/dxflake/ --update";
          dxboot = "nh os boot /home/khoa/dxflake/";
          dxtest = "nh os test /home/khoa/dxflake/";
          dxbuild = "nh os build /home/khoa/dxflake/";
          dxrollback = "nh os rollback";
          dxcheck = "nix flake check /home/khoa/dxflake/";
          dxgens = "nh os info";
          dxclean = "nh clean all";
          ".." = "cd ..";
          reboot = "systemctl reboot";
          shutdown = "systemctl poweroff";
          poweroff = "systemctl poweroff";
          sleep = "systemctl suspend";
          hibernate = "systemctl hibernate";
          lock = "hyprlock";
          ls = "lsd";
          ll = "lsd -l";
          la = "lsd -la";
          lt = "lsd --tree";
          lg = "lazygit";
          crc = "claude --rc";
        };
      };
    };
}
