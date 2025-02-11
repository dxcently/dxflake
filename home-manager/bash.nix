{
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
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland &> /dev/null
      fi
    '';
    initExtra = ''
      fastfetch
      #if [ -f $HOME/.bashrc-personal ]; then
      #source $HOME/.bashrc-personal
      #fi
    '';
    bashrcExtra = ''
           export PATH="$HOME/.config/emacs/bin:$PATH"
           eval "$(zoxide init bash)"
           eval "$(atuin init bash)"
           set -o vi
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
      khoa = true;
    };
    shellAliases = {
      sv = "sudo nvim";
      v = "nvim";
      nano = "nvim";
      flake-rebuild = "nh os switch /home/khoa/dxflake/";
      flake-update = "nh os switch /home/khoa/dxflake/ --update";
      gcCleanup = "nh clean all";
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lal = "lsd -al";
      ".." = "cd ..";
      mv = " mv -i";
      rm = "rm -i";
      cp = "cp -i";
      reboot = "systemctl reboot";
      shutdown = "shutdown -h now";
      fetch = "fastfetch";
      #neofetch = "neofetch --ascii ~/dxflake/home-manager/extras/ascii-neofetch";
      nix-list-generation = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'"; # thank you iynaix :>
      sdl = "spotdl download";
    };
  };
}
