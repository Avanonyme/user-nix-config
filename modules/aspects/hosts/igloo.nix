{ den, ... }:
{
  flake-file.inputs = {
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  #MicroVM guests aspects; for testing and deploying on host (current server host: cool)
  den.aspects.igloo = {
    # NixOS config of the VM itself
    nixos = { pkgs, ... }: {
      boot.loader.grub.enable = false;
      fileSystems."/" = {
        device = "/dev/null";  # required for microvm
        fsType = "ext4"; # Replace with "btrfs", "xfs", etc. based on your setup
      };
      environment.systemPackages = [ pkgs.htop ];
    };

    # microvm.nix-specific options (routed to microvm.vms.igloo.*)
    microvm = {
      autostart = true;
      # vcpu = 2;
      # mem = 1024;
    };
  };
}