{ den, ... }:
{
  den.aspects.igloo = {
    # NixOS config of the VM itself
    nixos = { pkgs, ... }: {
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";  # required for microvm
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