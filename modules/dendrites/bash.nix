{
  homeManager =
    { pkgs, ... }:
    {
      home.packages = with pkgs; [ lsd ];
      programs.bash = {
        enable = true;
        enableCompletion = true;
        profileExtra = ''
          if [ "$(tty)" = "/dev/tty1" ] && command -v Hyprland >/dev/null; then
            exec Hyprland &> /dev/null
          fi
        '';
        initExtra = ''
          fastfetch
        '';
        bashrcExtra = ''
          command -v mcfly >/dev/null && eval "$(mcfly init bash)"

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
          # Just the fast-moving first-party inputs, then switch. `dxupdate`
          # re-locks EVERYTHING (nixpkgs, hyprland, stylix, ...), a world rebuild
          # for what is usually a one-repo change. None of these inputs carries a
          # `rev=` in its URL (see flake.nix), so this is the whole "a new commit
          # landed" workflow. A bad upstream commit fails the BUILD, not the box;
          # `git checkout flake.lock` puts the old revs back.
          dxbump = "nix flake update --flake /home/khoa/dxflake melete-src mneme-src harnox-src eidolon aoide && nh os switch /home/khoa/dxflake/";
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
