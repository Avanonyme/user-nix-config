{ den, inputs, __findFile, ... }:
{
  den.aspects.cool = {
    includes = [
      <core/hostname>
      <core/networking>
      <core/openssh>
      den.aspects.headscale._.server
      den.aspects.sops
    ];

    # Host NixOS configuration
    nixos = { pkgs, lib, config, ... }: {
      networking.hostName = "cool";
      networking.hostId = "727b3488";

      # TODO: set a static IP or use DHCP
      networking.useDHCP = lib.mkDefault true;

      nix.settings.experimental-features = ["nix-command" "flakes"];
      nix.settings.trusted-users = [ "avanonyme" ];

      # Remote builder: allow incoming builds from tailnet
      nix.settings.max-jobs = 4;
      nix.buildMachines = []; # this is the builder, not a client

      environment.systemPackages = with pkgs; [
        vim
        git
        htop
        tailscale
      ];

      # TODO: set timezone
      time.timeZone = "America/Toronto";

      nixpkgs.config.allowUnfree = true;
    };

    homeManager = { pkgs, ... }: {
      home.packages = with pkgs; [
        ghostty
      ];
    };
  };
}
