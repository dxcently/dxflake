{ config, lib, pkgs, ... }:

let
  cfg = config.programs.bash;
  cfge = config.environment;
in
{
  programs.bash = {
    enable = true;
    enableCompletion = true;
    profileExtra = ''
      #if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
      #  exec Hyprland
      #fi
    '';
    /*initExtra = ''
      neofetch
      if [ -f $HOME/.bashrc-personal ]; then
        source $HOME/.bashrc-personal
      fi
    '' ; */
    sessionVariables = {
      khoa = true;
    };
    shellAliases = {
      sv="sudo nvim";
      flake-rebuild="nh os switch /home/khoa/dxflake/";
      flake-update="nah os switch /home/khoa/dxflake/ --update";
      gcCleanup="nh clean all";
      v="nvim";
      ls="lsd";
      ll="lsd -l";
      la="lsd -a";
      lal="lsd -al";
      ".."="cd ..";
      neofetch="neofetch --ascii ~/.config/ascii-neofetch";
    };
  };
}

