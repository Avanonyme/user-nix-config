{den, inputs,...}:
{
  den.aspects.nvidia = {
    nixos = {pkgs, host, ...}: {

      # Initrd modules for NVIDIA support
      boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];
      #boot.blacklistedKernelModules = [ "nouveau" ];
      #boot.extraModprobeConfig = ''
      #  blacklist nouveau
      #  options nouveau modeset=0
      #'';

      # Graphics and GPU settings
      services.xserver.enable = true;
      services.xserver.videoDrivers = ["nvidia"];

      hardware.graphics = {
        enable = true;
        enable32Bit = true;
      }; #hardware.opengl has been changed to hardware.graphics

      nixpkgs.config.nvidia.acceptLicense = true;
      hardware.nvidia = {
        modesetting.enable = true;
        powerManagement.enable = false;
        powerManagement.finegrained = false;
        open = false;  # Important: Disable open-source driver
        nvidiaSettings = true;
        package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
      };

      #prime = {
      #    offload.enable = powerManagement.finegrained;
      #    offload.enableOffloadCmd = prime.offload.enable;
      #  };

    };
  };
}
