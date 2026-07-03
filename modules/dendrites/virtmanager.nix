{username, config, lib, ...}: {
  config = lib.mkIf config.dx.aggregations.desktop {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///system"];
          uris = ["qemu:///system"];
        };
      };
    };
  };
}
