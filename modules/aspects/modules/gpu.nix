{den, config, inputs,...}:
# nvidia config is only working for boreal host.
#any way to generalize this module is welcomed

{
  den.aspects.gpu = {
    provides.amd = {
      nixos = {pkgs,config, host, ...}: {

        #Kernel; more options in nvidia aspect # move nvidia and amdpgu to GPU aspect
        boot.initrd.kernelModules = ["amdgpu"];
        boot.kernelModules = [ "kvm-intel" ];

        #set graphics
        services.xserver.videoDrivers = ["amdgpu"];
        hardware.firmware = [ pkgs.linux-firmware ]; #for Error: Direct firmware load failure
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };
      };
    };
    provides.sync_gpu = {
      nixos = {pkgs,config, host, ...}: {
        includes = [den.aspects.gpu._.amd];

        # Initrd modules for NVIDIA support
        boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" "nvidia" "i915" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"];

        # Graphics and GPU settings
        services.xserver.enable = true;
        services.xserver.videoDrivers = ["nvidia"];

        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };
        nixpkgs.config.nvidia.acceptLicense = true;
        hardware.nvidia = {
          prime = {
            sync.enable = true;
            #main
            amdgpuBusId = "PCI:4:0:0";
            #legacy
            nvidiaBusId = "PCI:1:0:0";
          };
          modesetting.enable = true;
          powerManagement.enable = false;
          powerManagement.finegrained = false;
          open = false;  # Important: Disable open-source driver
          nvidiaSettings = true;
          package = config.boot.kernelPackages.nvidiaPackages.legacy_470;
        };
      };
    };


  };
}
