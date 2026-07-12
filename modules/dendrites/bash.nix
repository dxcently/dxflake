{username, ...}: {
  home-manager.users.${username} = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.programs.bash;
    cfge = config.environment;
  in {
    home.packages = with pkgs; [lsd];
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
        dxboot = "nh os boot /home/khoa/dxflake/";
        dxtest = "nh os test /home/khoa/dxflake/";
        dxbuild = "nh os build /home/khoa/dxflake/";
        dxrollback = "nh os rollback";
        dxcheck = "nix flake check /home/khoa/dxflake/";
        dxgens = "nh os info";
        dxclean = "nh clean all";
        nix-search = "nh search";
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
