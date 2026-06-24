{ den, inputs, pkgs, ... }:
{

# Igloo guest VM — runs as a guest of boreal via microvm.guests
# run via systemctl start microvm@igloo.service

# in den.nix:  microvm.guests = [den.hosts.x86_64-linux.igloo];

# vm host declaration
den.hosts.x86_64-linux.igloo = {
   intoAttr = [];  # dont produce Guest nixosConfiguration at flake output

   users.avanonyme = {};
   users.tux = {};
 };
# base vm config
den.aspects.igloo = {
    nixos = {
      imports = [inputs.microvm.nixosModules.microvm];
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";  # required for guest model
      fileSystems."/".fsType = "tmpfs";      # microvm needs fsType defined
      users.users.root.password = "";

      environment.systemPackages = [ inputs.nixpkgs.legacyPackages.x86_64-linux.htop ];

      microvm = {
        hypervisor = "stratovirt"; # default qemu
        socket = "control.socket";

        # Enable writable nix store overlay so nix-daemon works.
        # This is required for home-manager activation.
        writableStoreOverlay = "/nix/.rw-store";
        volumes = [{
          mountPoint = "/var";
          image = "var.img";
          size = 256;
        }];
      };
    };
  };

  # Standalone runnable microvm package — nix run .#igloo-runner

  # den host declaration
  den.hosts.x86_64-linux.igloo-runner = {
   intoAttr = ["microvms" "igloo-runner"];  # not nixosConfigurations — this is a runnable package
   users.tux ={};
  };
  den.hosts.aarch64-darwin.igloo-runner = {
   intoAttr = ["microvms" "igloo-runner"];
   users.tux ={};
  };

  # base runner config
  den.aspects.igloo-runner = {
    nixos = {   
      includes = [
      ];
      nixos = {
        imports = [inputs.microvm.nixosModules.microvm];
        users.users.root.password = "";
        environment.systemPackages = [ inputs.nixpkgs.legacyPackages.x86_64-linux.htop ];

        microvm = {
          hypervisor = "stratovirt";
          socket = "control.socket";
          volumes = [{
            mountPoint = "/var";
            image = "var.img";
            size = 256;
          }];
          shares = [{
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }];
        };
      };
    };
    darwin = {
      # linux builder
      nix = {
        distributedBuilds = true;
        linux-builder = {
          enable = true;
          package = pkgs.darwin.linux-builder;
          systems = [ "aarch64-linux" ];
        };
      };
      microvm = {
        hypervisor = "vfkit";
        vcpu = 4;
        mem = 8192; # 8GB
        # graphics.enable = true;
        writableStoreOverlay = "/nix/.rw-store";
        volumes = [
          {
            image = "nix-store-overlay.img";
            mountPoint = "/nix/.rw-store";
            size = 40960; # 40GB
          }
        ];
        shares = [
          {
            proto = "virtiofs";
            tag = "ro-store";
            source = "/nix/store";
            mountPoint = "/nix/.ro-store";
          }
        #  {
        #    proto = "virtiofs";
        #    tag = "projects";
        #    source = "/Users/avanonyme+/Projects";
        #    mountPoint = "/projects";
        #  }
        ];
        interfaces = [
          {
            type = "user";
            id = "usernet";
            mac = "02:00:00:01:01:01";
          }
        ];
      };



    };
  };
}
