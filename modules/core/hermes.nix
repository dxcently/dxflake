{ inputs, config, ... }: {
  imports = [ inputs.hermes-agent.nixosModules.default ];

  sops.secrets."hermes/api-key" = {
    sopsFile = ../../secrets/hermes.yaml;
    owner = "root";
    mode = "0400";
  };

  # Renders /run/secrets/hermes-env at activation; never hits the Nix store.
  sops.templates."hermes-env" = {
    content = ''
      HERMES_API_KEY=${config.sops.placeholder."hermes/api-key"}
    '';
    path = "/run/secrets/hermes-env";
    mode = "0400";
  };

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings = {
      model.default = "";
      api.baseUrl = "https://chat.hpc.fau.edu/api";
    };
    enableWebUi = false;
    environmentFiles = [ "/run/secrets/hermes-env" ];
  };
}
