# den.aspects.sops — secrets management via sops-nix
#
# Secrets are stored in encrypted YAML files under secrets/.
#
# Encryption workflow:
#   1. One-time: age-keygen -o ~/.config/sops/age/keys.txt
#   2. Create file: sops modules/secrets/secrets.yaml
#      Inside:  deepseek_api_key: sk-xxx...
#               openai_api_key: sk-xxx...
#   3. Edit anytime: sops modules/secrets/secrets.yaml



{den, config, inputs, ...}:
{

  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows ="nixpkgs";
  };

  den.aspects.security.sops = 
  let
    # Paths relative to this nix file:
    #   ./ = modules/aspects/modules/
    #   ../../.. = repo root (~/.config/nix)
    secretsDir = ../../../secrets;
    secretFile = secretsDir + "/secrets.yaml";

# Couple options available in brackets:
#      mode:
#       ??
#      owner:
#      which owner this api key belongs to according to .sops.yaml
#      sopsFile: 
#      Tells sops-nix which file to decrypt. 
#      The key name inside the file uses underscores (not /).
#      Secret "deepseek/api_key" → looks up deepseek_api_key in ai.yaml

    commonSecrets = {
      # media 
      #"sonarr/api_key" = {};
      #"sonarr/password" = {};
      #"radarr/api_key" = {};
      #"radarr/password" = {};
      #"lidarr/api_key" = {};
      #"lidarr/password" = {};
      #"prowlarr/api_key" = {};
      #"prowlarr/password" = {};
      #"indexer-api-keys/NZBFinder" = {};
      #"indexer-api-keys/NzbPlanet" = {};
      #"jellyfin/avanonyme_password" = {};
      #"jellyseerr/api_key" = {};
      #"sabnzbd/api_key" = {};
      #"sabnzbd/nzb_key" = {};
      #"usenet/eweka/username" = {};
      #"usenet/eweka/password" = {};

      # AI
      "hermes_env/deepseek/api_key" = {};
      "hermes_env/anthropic/api_key" = {};

      #vpn
      "headscale/auth_key" = {};
      #"tailscale/auth_key" = {};
      "mullvad_account_number" = {};

      # network
      "ddclient/password" = {};
    };
    nixosOnlySecrets = {
      "microvm/sealskin_key" = {
        group = "kvm";
        mode = "0440";
      };
    };

    # following https://guekka.github.io/nixos-server-2/
    isEd25519 = k: k.type == "ed25519";
    getKeyPath = k: k.path;
    keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
    
  in
  {
    nixos = {config, ... }:{
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops = {
        defaultSopsFile = secretFile;
        age.sshKeyPaths = [];
        age.keyFile = "/home/avanonyme/.config/sops/age/keys.txt";

        secrets = commonSecrets // nixosOnlySecrets;

        templates."hermes.env" = {
          content = ''
            DEEPSEEK_API_KEY=${config.sops.placeholder."hermes_env/deepseek/api_key"}
            ANTHROPIC_API_KEY=${config.sops.placeholder."hermes_env/anthropic/api_key"}
          '';
        };

      };
    };

    darwin = {user, config, ...}: {
      imports = [ inputs.sops-nix.darwinModules.sops ];

      sops = {
        defaultSopsFile = secretFile;
        age.sshKeyPaths = [];
        age.keyFile = "/Users/${user.userName}/.config/sops/age/keys.txt";
        secrets = commonSecrets;
      };
    };

    homeManager = {user, pkgs, ...}: {
      imports = [ inputs.sops-nix.homeManagerModules.sops ];

      sops = {
        defaultSopsFile = secretFile;
        age.keyFile =
          if pkgs.stdenv.hostPlatform.isDarwin
          then "/Users/${user.userName}/.config/sops/age/keys.txt"
          else "/home/${user.userName}/.config/sops/age/keys.txt";

        secrets = commonSecrets;
      };

    };
  };
}
