{ den, inputs, ... }:
{
  # Igloo guest VM — runs as a guest of boreal via microvm.guests
  den.aspects.igloo = {
    nixos = {
      imports = [inputs.microvm.nixosModules.microvm];
      boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";  # required for guest model
      fileSystems."/".fsType = "tmpfs";       # microvm needs fsType defined
      environment.systemPackages = [ inputs.nixpkgs.legacyPackages.x86_64-linux.htop ];

      microvm = {
        hypervisor = "qemu";
        socket = "control.socket";
        volumes = [{
          mountPoint = "/var";
          image = "var.img";
          size = 256;
        }];
        shares = [{
          proto = "9p";
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
        }];
      };
    };
  };

  # Standalone runnable microvm package — nix run .#igloo-runner
  den.aspects.igloo-runner = {
    nixos = {
      imports = [inputs.microvm.nixosModules.microvm];
      users.users.root.password = "";
      environment.systemPackages = [ inputs.nixpkgs.legacyPackages.x86_64-linux.htop ];

      microvm = {
        hypervisor = "qemu";
        socket = "control.socket";
        volumes = [{
          mountPoint = "/var";
          image = "var.img";
          size = 256;
        }];
        shares = [{
          proto = "9p";
          tag = "ro-store";
          source = "/nix/store";
          mountPoint = "/nix/.ro-store";
        }];
      };
    };
  };
}
