{inputs, ...}: {
  imports = [inputs.hermes-agent.nixosModules.default];

  services.hermes-agent = {
    enable = true;
    addToSystemPackages = true;
    settings.model.default = "";
    enableWebUi = false;
    # API keys must NOT go in the Nix store — point to a secrets file:
    # environmentFiles = [ /run/secrets/hermes-env ];
  };
}
