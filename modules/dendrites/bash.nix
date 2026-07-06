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
        sv = "sudo nvim";
        v = "nvim";
        nano = "nvim";
        flake-rebuild = "nh os switch /home/khoa/dxflake/";
        flake-update = "nh os switch /home/khoa/dxflake/ --update";
        flake-clean = "nh clean all";
        ".." = "cd ..";
        reboot = "systemctl reboot";
        shutdown = "shutdown -h now";
        nix-list-generation = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'"; # thank you iynaix :>
        sdl = "spotdl download";
        lg = "lazygit";
        claudy = "claude --rc";
      };
    };
  };
}
