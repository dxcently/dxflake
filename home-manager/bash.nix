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
    #blesh.enable = true;
    profileExtra = ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec Hyprland &> /dev/null
      fi
    '';
    initExtra = ''
      fastfetch
    '';
    bashrcExtra = ''
      eval "$(zoxide init bash)"
      eval "$(atuin init bash)"
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
      nix-clean = "nh clean all";
      ls = "lsd";
      ll = "lsd -l";
      la = "lsd -a";
      lal = "lsd -al";
      ".." = "cd ..";
      reboot = "systemctl reboot";
      shutdown = "shutdown -h now";
      nix-list-generation = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | grep current | awk '{print $1}'"; # thank you iynaix :>
      sdl = "spotdl download";
      lg = "lazygit";
    };
  };
}
