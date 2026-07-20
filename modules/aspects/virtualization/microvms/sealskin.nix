# A small layer of leather blocking the cold from outside
# Headscale  microvm 
{den,inputs,pkgs,...}:
let
  ipadd="10.0.83.6";
in
{
  #used by microvm guest host
  den.aspects.sealskin ={config, ...}:{ 
    includes = with den.aspects;[
      security.sops

      (microvms.igloo{
        ipAddress = "${ipadd}"; 
        mac ="02:00:00:00:00:06" ;
        tapID = "microvm6"; 
        workspace = "/srv/sealskin"; #or elsewhere, then services.headscale.settings.acl.policy.path = "/srv/sealskin/acls.yaml";
      })

      networking.headscale.server
    ];

    nixos = {host, lib, ...}: {
      imports = [ inputs.sops-nix.nixosModules.sops ];
      microvm={
        credentialFiles."sops-age-key" = "/run/secrets/microvm/sealskin_key";

        # source: https://blog.koch.ro/posts/2024-03-17-minimal-vms-nix-microvm.html
        #forwardPorts = [
        #  { from = "host"; host.port = 2222; guest.port = 22; }
        #  { from = "guest"; host.port = 5432; guest.port = 5432; } # postgresql
        #];
      };
      sops.age.keyFile = lib.mkForce "/run/host-credentials/sops-age-key";
      sops.defaultSopsFile = lib.mkForce ../../../../secrets/secrets.yaml;
      sops.secrets."headscale/auth_key" = {};
    };
  };

  #the config used by the metal host
  den.aspects.virtualization.microvms.sealskin = {config,...}:{
    nixos = {host,...}: {
      microvm.vms."sealskin" = {
        autostart = true;
      };
      networking.nat = {
        enable = true;
        externalInterface = "enp1s0";
        forwardPorts = [
        { proto = "tcp"; sourcePort = 80;  destination = "${ipadd}:80"; }
        { proto = "tcp"; sourcePort = 443; destination = "${ipadd}:443"; }
        ];
      };
    };
  };

  # Standalone runnable microvm package — nix run .#sealskin-runner
  den.hosts.x86_64-linux.sealskin-runner = {
   intoAttr = ["microvms" "sealskin-runner"];
   users.tux ={};
  };
  den.aspects.sealskin-runner = {

      nixos = {
        imports = [inputs.microvm.nixosModules.microvm];
        users.users.root.password = ""; #all right for a one off runner

        microvm = {
          hypervisor = "stratovirt";
          socket = "control.socket";
          writableStoreOverlay = "/nix/.rw-store";
          volumes = [{
            mountPoint = "/var";
            image = "var.img";
            size = 8192;
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
}
