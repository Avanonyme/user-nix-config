# MicroVM Den integration
# See https://den.denful.dev/tutorials/microvm/
#     https://github.com/denful/den/tree/main/templates/microvm  
{ den, inputs, pkgs, ... }:{
  flake-file.inputs = {
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  #Activation — import microvm integration
    imports = [
      # allows the creation of microvm.guests in host 
      (import "${inputs.den}/templates/microvm/modules/microvm-integration.nix")

      # expose declaredrunner for each hosts as flake output
      (import "${inputs.den}/templates/microvm/modules/microvm-runners.nix") 
    ];
  den.aspects.microvm = {...}: {
    includes = [den.aspects.microvm-net];

    # https://github.com/aspauldingcode/.dotfiles/blob/master/modules/microvm.nix
    darwin ={ pkgs, inputs, ... }:
      let
        microvmRunWrapper = pkgs.writeShellApplication {
          name = "microvm-run";
          runtimeInputs = [ pkgs.nix ];
          text = ''
            set -eu
            runner="$(${pkgs.nix}/bin/nix build --no-link --print-out-paths \
              "/etc/nix-darwin/.dotfiles#nixosConfigurations.microvm.config.microvm.runner.vfkit")"
            exec "$runner/bin/microvm-run" "$@"
          '';
        };
      in
      {
        environment.systemPackages = [
          inputs.determinate-nix.packages.${pkgs.stdenv.hostPlatform.system}.default
          microvmRunWrapper
        ];
      };
  };
# Host-side networking for VM connectivity, as a den aspect (NixOS options can't
# live at the flake-module top level). Include den.aspects.microvm-net in the vm host.
# See https://microvm-nix.github.io/microvm.nix/advanced-network.html
  den.aspects.microvm-net.nixos = { ... }: {
    systemd.network.enable = true;

    systemd.network.netdevs."10-microvm".netdevConfig = {
      Kind = "bridge";
      Name = "microvm";
    };

    systemd.network.networks."10-microvm" = {
      matchConfig.Name = "microvm";
      addresses = [ { Address = "10.0.83.1/24"; } ];
      networkConfig = {
        ConfigureWithoutCarrier = true;
      };
    };

    systemd.network.networks."21-microvm-tap" = {
      matchConfig.Name = "microvm*";
      networkConfig.Bridge = "microvm";
    };

    networking.nat = {
      enable = true;
      internalInterfaces = [ "microvm" ]; # The bridge where you want to provide Internet access
      externalInterface = "enp1s0"; # Change this to the interface with upstream Internet access
    };
  };

/* Port forwarding
Isolating your public Internet services is a great use-case for virtualization. 
But how does traffic get to you when your MicroVMs have private IP addresses 
behind NAT?

NixOS has got you covered with the networking.nat.forwardPorts option! 
This example forwards TCP ports 80 (HTTP) and 443 (HTTPS) to other hosts:
networking.nat = {
  enable = true;
  forwardPorts = [ {
    proto = "tcp";
    sourcePort = 80;
    destination = my-addresses.http-reverse-proxy.ip4;
  } {
    proto = "tcp";
    sourcePort = 443;
    destination = my-addresses.https-reverse-proxy.ip4;
  } ];
};

*/
  den.aspects.port_forward = {port,address,...}:{
    networking.nat = {
      enable = true;
      forwardPorts = [ {
        proto = "tcp";
        sourcePort = port;
        destination = address;
      } ];
    };
  };

}