{
  username,
  config,
  lib,
  ...
}:
{
  config = {
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
        #
        # `addresses` is stated rather than left unset because the merge only
        # rewrites the keys it is given: an entry without the field leaves
        # whatever a GUI hand-added sitting there. sakaki had collected an
        # `http://sakaki:8384/` and the `https://syncthing.necoconeco.net/` GUI
        # URL on all four devices, and a device address can only ever be a sync
        # transport (`tcp://`, `quic://`, `relay://`, `dynamic`) — those two
        # just log "unknown address scheme". mkDefault, so a host can still pin
        # a real one, as chiyo does for sakaki's tailnet + tunnel addresses.
        settings.devices = {
          osaka = {
            id = "ICIE4UH-666HVCM-KPAEZQ7-3OBPKGH-SASKGQL-WTEOB6A-2HKH5T3-YUGSJAM";
            addresses = lib.mkDefault [ "dynamic" ];
          };
          chiyo = {
            id = "MK4SI4Y-JHQKOSU-36UTDSI-3RVV2MU-D7B2SH7-LFYPPT5-QJJHVVT-SRTXAAA";
            addresses = lib.mkDefault [ "dynamic" ];
          };
          sakaki = {
            id = "WARFWSG-FCCCDJN-MTDRJZO-S4KX2DZ-WYOMZK7-3MWDZ4F-TNJYJJT-QWN6DAW";
            addresses = lib.mkDefault [ "dynamic" ];
          };
          phone = {
            id = "ZQXTIHW-7EBAKMX-6ETRCJQ-QSG6OI7-4TFBE5O-W5VD4UE-E2JH2HV-O6ATDQQ";
            addresses = lib.mkDefault [ "dynamic" ];
          };
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

    # nixpkgs' syncthing module defines syncthing-init.service with
    # Requisite=syncthing.service (plus After=). Requisite fails the start
    # job if syncthing.service is not ALREADY active — fine at boot, where
    # one transaction pulls in both units and After= orders them, but a
    # landmine during switch-to-configuration: the -ng rewrite submits one
    # StartUnit call per unit in arbitrary HashMap order, so whenever
    # syncthing-init's job runs before syncthing.service's job is queued the
    # job dies with result 'dependency' and the whole activation exits 4
    # (nh then aborts with "Activation (test) failed"). Seen 2026-08-13.
    # Wants+After keeps the same boot/switch semantics without the failure
    # mode: if syncthing isn't up yet it gets pulled in and ordered after,
    # and merge-syncthing-config already tolerates an API that isn't
    # answering yet (it polls, then gives up gracefully).
    systemd.services.syncthing-init = {
      requisite = lib.mkForce [ ];
      wants = [ "syncthing.service" ];
    };
  };
}
