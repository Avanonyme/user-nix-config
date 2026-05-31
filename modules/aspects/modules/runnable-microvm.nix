{den,...}:{  
  
  den.hosts.x86_64-linux.runnable-microvm = {
    intoAttr = [
        "microvms"
        "runnable-microvm"
    ]; # pkgs; not intended to be used from nixosConfigurations
  };
  #MicroVM runnable aspect; for running as packages
  #
  #See https://den.denful.dev/tutorials/microvm/
  #And https://microvm-nix.github.io/microvm.nix/packages.html
  den.aspects.runnable-microvm = {inputs, ...}:{

    nixos = {

      imports = [ inputs.microvm.nixosModules.microvm ];

      users.users.root.password = "";

      # There's not much need to have a forwarding microvm class for runnable vms
      microvm = {

        volumes = [
          {
            mountPoint = "/var";
            image = "var.img";
            size = 256;
          }
        ];

        shares = [
          {
            # use proto = "virtiofs" for MicroVMs that are started by systemd
            proto = "9p";
            tag = "ro-store";
            # a host's /nix/store will be picked up so that no
            # squashfs/erofs will be built for it.
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        ];

        # "qemu" has 9p built-in!
        hypervisor = "qemu";
        socket = "control.socket";
        
      };
    };
  };
}