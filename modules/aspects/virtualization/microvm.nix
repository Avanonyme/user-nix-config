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
  den.aspects.virtualization.microvm-darwin= {inputs, ...}: {
    #includes = [den.aspects.microvm-bridge]; #metal side aspect

    # https://github.com/aspauldingcode/.dotfiles/blob/master/modules/microvm.nix
    darwin ={ pkgs, ... }:
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
          inputs.determinate.packages.${pkgs.stdenv.hostPlatform.system}.default
          microvmRunWrapper
        ];
      };
  };
# metal host-side networking for VM connectivity, as a den aspect (NixOS options can't
# live at the flake-module top level). Include den.aspects.microvm-net in the metal host.
# See https://microvm-nix.github.io/microvm.nix/advanced-network.html
  den.aspects.virtualization.microvm-bridge.nixos = { ... }: {
    systemd.network.enable = true;

    systemd.network.netdevs."10-microbr".netdevConfig = {
      Kind = "bridge";
      Name = "microbr";
    };

    systemd.network.networks."10-microbr" = {
      matchConfig.Name = "microbr";
      addresses = [ { Address = "10.0.83.1/24"; } ];
      networkConfig = {
        ConfigureWithoutCarrier = true;
      };
    };

    systemd.network.networks."11-microvm-tap" = {
      matchConfig.Name = "microvm*";
      networkConfig.Bridge = "microbr";
    };

    networking.nat = {
      enable = true;
      internalInterfaces = ["microbr"]; # The bridge where you want to provide Internet access
      externalInterface = "enp1s0"; # Change this to the interface with upstream Internet access
    };
  };
}