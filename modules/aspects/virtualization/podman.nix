{ den, ... }:
{
  # following https://bkiran.com/blog/deploying-containers-nixos
  # NOTE: class blocks (nixos = ...;) are required — a bare attrset of NixOS
  # options at aspect top level is silently not applied by den.
  den.aspects.podman = {
    nixos = { pkgs, ... }: {
      virtualisation = {
        containers.enable = true;
        podman = {
          enable = true;
          dockerCompat = true; # /var/run/docker.sock shim for docker-compose etc.
          # DNS between containers on the default network (container names resolve)
          defaultNetwork.settings.dns_enabled = true;
        };
        # oci-containers defaults to podman when podman is enabled; set explicitly
        oci-containers.backend = "podman";
      };

      # Useful other development tools
      environment.systemPackages = with pkgs; [
        dive # look into docker image layers
        podman-tui # status of containers in the terminal
        docker-compose # start group of containers for dev
        #podman-compose # start group of containers for dev
      ];
    };
  };
}
