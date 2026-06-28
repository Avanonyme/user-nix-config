{ den, inputs, pkgs, ... }:
{

# Igloo guest VM — runs as a guest of boreal via microvm.guests
# run via systemctl start microvm@igloo.service

# in den.nix:  microvm.guests = [den.hosts.x86_64-linux.igloo];

# vm host declaration
den.hosts.x86_64-linux.igloo = {
   intoAttr = [];  # dont produce Guest nixosConfiguration at flake output

   users.avanonyme = {includes=[den.aspects.avanonyme.headless];};
   users.tux = {};
 };
# microvm-base from: https://michael.stapelberg.ch/posts/2026-02-01-coding-agent-microvm-nix/
den.aspects.igloo = {ipAddress, mac, tapID, workspace, ...}:{
    nixos ={host, config}: {
      imports = [inputs.microvm.nixosModules.microvm];
      #boot.loader.grub.enable = false;
      fileSystems."/".device = "/dev/null";  # required for guest model
      fileSystems."/".fsType = "tmpfs";      # ephemeral (default)

      services.resolved.enable = true;
      networking.useDHCP = false;
      networking.useNetworkd = true;
      networking.tempAddresses = "disabled";
      systemd.network.enable = true;
      systemd.network.networks."10-e" = {
        matchConfig.Name = "e*";
        addresses = [ { Address = "${ipAddress}/24"; } ];
        routes = [ { Gateway = "10.0.83.1"; } ];
      };
      networking.nameservers = [
        "8.8.8.8"
        "1.1.1.1"
      ];

      # Disable firewall for faster boot and less hassle;
      # we are behind a layer of NAT anyway.
      networking.firewall.enable = false;

      systemd.settings.Manager = {
        # fast shutdowns/reboots! https://mas.to/@zekjur/113109742103219075
        DefaultTimeoutStopSec = "5s";
      };

      # Fix for microvm shutdown hang (issue #170):
      # Without this, systemd tries to unmount /nix/store during shutdown,
      # but umount lives in /nix/store, causing a deadlock.
      systemd.mounts = [
        {
          what = "store";
          where = "/nix/store";
          overrideStrategy = "asDropin";
          unitConfig.DefaultDependencies = false;
        }
      ];

      # Use SSH host keys mounted from outside the VM (remain identical).
      services.openssh.hostKeys = [
        {
          path = "/etc/ssh/host-keys/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];

      environment.systemPackages = [ inputs.nixpkgs.legacyPackages.x86_64-linux.htop ];

      microvm = {
        credentialFiles = {
          "sops-age-key" = config.sops.secrets."microvm/igloo_key".path;
        };
        hypervisor = "qemu"; # default
        vcpu = 8;
        mem=4096;
        socket = "control.socket";

        # Enable writable nix store overlay so nix-daemon works.
        # This is required for home-manager activation.
        writableStoreOverlay = "/nix/.rw-store";

        interfaces = [{
          type = "tap";
          id = tapID;
          mac = mac;
        }];
        volumes = [{
          mountPoint = "/var";
          image = "var.img";
          size = 8192; #MB
        }];
        shares = [{
            proto = "virtiofs";
            tag = "workspace";
            source = workspace;
            mountPoint = workspace;
        }];
        config = {        
        # Verify which exist
        #ls /run/host-credentials/
        #ls /run/credentials/
        sops.age.keyFile = "/run/host-credentials/sops-age-key"; #wire credential to sops
        sops.defaultSopsFile = ../../../secrets/secrets.yaml;
        
        # Now the VM can decrypt the OIDC secret and admin password!
        sops.secrets."kanidm/admin_password" = { owner = "kanidm"; };
        sops.secrets."kanidm/headscale_oidc_secret" = { owner = "headscale"; };
        };
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
