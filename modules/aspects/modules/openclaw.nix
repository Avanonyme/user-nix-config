{den, inputs, ...}:
{
  flake-file.inputs.nix-openclaw = {
    url = "github:openclaw/nix-openclaw";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # sops-nix is declared in sops.nix too; flake-file merges duplicate inputs fine
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.openclaw = {
    # Per-user home-manager config (works on Linux and macOS)
    homeManager = { pkgs, user, config, ... }: {
      imports = [
        inputs.nix-openclaw.homeManagerModules.openclaw
        inputs.sops-nix.homeManagerModules.sops
      ];

      sops = {
        defaultSopsFile = ../../../secrets/secrets.yaml;
        # Derives the age key from the user's SSH key at activation time.
        # Run: ssh-to-age < ~/.ssh/id_ed25519.pub  to get the age public key for .sops.yaml
        age.sshKeyPaths = [ "/home/${user.name}/.ssh/id_ed25519" ];
        secrets."openclaw/api_key" = {};
      };

      # Uncomment once secrets/secrets.yaml is created and encrypted.
      # services.openclaw = {
      #   enable = true;
      #   instances.default = {
      #     provider = "anthropic";
      #     apiKeyFile = config.sops.secrets."openclaw/api_key".path;
      #   };
      # };
    };

    # NixOS gateway service (Linux only — boreal)
    nixos = { pkgs, ... }: {
      imports = [ inputs.nix-openclaw.nixosModules.openclaw-gateway ];
    };
  };
}
