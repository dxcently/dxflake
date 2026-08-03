{ username, ... }: {
  # TTY-less agent surfaces (Melete, Kimi CLI) can't answer a sudo password
  # prompt, so rebuilds stall. Same rationale as the scoped systemctl grants
  # in mneme/immich/jellyfin: NOPASSWD for the nixos-rebuild binary only,
  # not a general sudo grant. Lets `sudo nixos-rebuild switch --flake ...`
  # (and nh, which wraps it) run unattended.
  security.sudo.extraRules = [
    {
      users = [ username ];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];

  home-manager.users.${username} =
    {
      pkgs,
      inputs,
      ...
    }:
    {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 1w --keep 10";
        };
        flake = "/home/khoa/dxflake/";
      };
    };
}
