{
  username,
  config,
  lib,
  ...
}:
{
  options.dx.syncthing.enable = lib.mkEnableOption "syncthing";
  config = lib.mkIf config.dx.syncthing.enable {
    services = {
      syncthing = {
        enable = true;
        user = username;
        dataDir = "/home/${username}/Magi";
        configDir = "/home/${username}/.config/syncthing";
        # GUI login: username in the clear, password from sops.
        # guiPasswordFile is bcrypt-hashed and PATCHed in by syncthing-init,
        # which runs as `user`, so that user must own the secret.
        settings.gui.user = username;
        guiPasswordFile = config.sops.secrets."syncthing/gui-password".path;

        # Device IDs are public keys, not secrets. Full mesh: every host lists
        # all peers; syncthing recognises and skips its own ID.
        settings.devices = {
          osaka.id = "ICIE4UH-666HVCM-KPAEZQ7-3OBPKGH-SASKGQL-WTEOB6A-2HKH5T3-YUGSJAM";
          chiyo.id = "MK4SI4Y-JHQKOSU-36UTDSI-3RVV2MU-D7B2SH7-LFYPPT5-QJJHVVT-SRTXAAA";
          sakaki.id = "WARFWSG-FCCCDJN-MTDRJZO-S4KX2DZ-WYOMZK7-3MWDZ4F-TNJYJJT-QWN6DAW";
          phone.id = "ZQXTIHW-7EBAKMX-6ETRCJQ-QSG6OI7-4TFBE5O-W5VD4UE-E2JH2HV-O6ATDQQ";
        };
        settings.folders."Magi" = {
          id = "vmvrr-kwdze";
          path = "/home/${username}/Magi";
          devices = [
            "osaka"
            "chiyo"
            "sakaki"
            "phone"
          ];
        };
      };
    };

    sops.secrets."syncthing/gui-password" = {
      sopsFile = ../../secrets/syncthing.yaml;
      owner = username;
    };
  };
}
