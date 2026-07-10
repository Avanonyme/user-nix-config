# A small layer of leather blocking the cold from outside
# Headscale  microvm 
{den,inputs,pkgs,...}:
let
  ipadd="10.0.83.6";
in
{
  #used by sealskin guest host
  den.aspects.sealskin ={config, ...}:{ 
    includes = with den.aspects;[
      security.sops

      (microvms.igloo{
        ipAddress = "${ipadd}"; 
        mac ="02:00:00:00:00:06" ;
        tapID = "microvm6"; 
        workspace = "/srv/sealskin"; #or elsewhere
      })

      networking.headscale.server
    ];
    nixos = {host, lib, ...}:{
      microvm ={

        credentialFiles = {
          "sops-age-key" = config.sops.secrets."microvm/sealskin_key".path;
        };
      };
      # Verify which exist
      #ls /run/host-credentials/
      #ls /run/credentials/
      sops.age.keyFile = lib.mkForce "/run/host-credentials/sops-age-key"; #wire credential to sops
      sops.defaultSopsFile = ../../../secrets/secrets.yaml;
      sops.secrets."headscale/auth_key" = { };
    };
  };

  #the config used by the metal host
  den.aspects.virtualization.microvms.sealskin = {config,...}:{
    nixos = {host,...}:{
      microvm.vms."sealskin" = {
        autostart = true;
      };
      networking.nat = {
        enable = true;
        forwardPorts = [
        { proto = "tcp"; sourcePort = 80;  destination = "${ipadd}:80"; }
        { proto = "tcp"; sourcePort = 443; destination = "${ipadd}:443"; }
      ];};
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
        users.users.root.password = "";

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