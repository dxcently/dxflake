{username, ...}: {
  config = {
    home-manager.users.${username} = {
      pkgs,
      config,
      ...
    }: {
      programs.floorp = {
        enable = false;
        /*
        profiles.dx = {
        name = "dx";
        isDefault = true;
        /*
          settings = {
          "extensions.autoDisableScopes" = 0;
        };
        */
        /*
            extraConfig = ''
            user_pref("accessibility.typeaheadfind.flashBar", 0);
            ...
            '';
          */
        #};
      };
    };
  };
}
