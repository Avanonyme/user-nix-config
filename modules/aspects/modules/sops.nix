{den, config, inputs, user, ...}:
{
  # 1. define inputs, and add to flake.nix
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows ="nixpkgs";
  };


  # following https://guekka.github.io/nixos-server-2/
  den.aspects.sops = 
  let
    isEd25519 = k: k.type == "ed25519";
    getKeyPath = k: k.path;
    keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
  in
  {
    nixos = {
      imports = [
        inputs.sops-nix.nixosModules.sops
      ];

      sops = {
        defaultSopsFile = ./../../../.sops.yaml; #aspect/aspect/module/dotfiles
        age.sshKeyPaths = [];
        age.keyFile = "/home/${user.userName}/.config/sops/age/keys.txt";

        secrets = {
          "sonarr/api_key" = {};
          "sonarr/password" = {};
          "radarr/api_key" = {};
          "radarr/password" = {};
          "lidarr/api_key" = {};
          "lidarr/password" = {};
          "prowlarr/api_key" = {};
          "prowlarr/password" = {};
          "indexer-api-keys/NZBFinder" = {};
          "indexer-api-keys/NzbPlanet" = {};
          "jellyfin/avanonyme_password" = {};
          "jellyseerr/api_key" = {};
          "mullvad-account-number" = {};
          "sabnzbd/api_key" = {};
          "sabnzbd/nzb_key" = {};
          "usenet/eweka/username" = {};
          "usenet/eweka/password" = {};

          "deepseek/api_key" = {};

        };
      };
    };
  };
}
