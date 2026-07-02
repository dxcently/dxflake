{username, ...}: {
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
}
