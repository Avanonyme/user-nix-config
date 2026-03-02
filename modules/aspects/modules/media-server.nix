{den, inputs, ...}:
{
  # 1 define inputs, and add to flake.nix
 flake-file.inputs.reticulum-flake = {
   url = "git+https://codeberg.org/adingbatponder/reticulum_nixos_flake.git";
   inputs.nixpkgs.follows = "nixpkgs";
 };
  
  # 2. Configure tailscale media server
  den.aspects.media-server = {host,...}: {
    imports = [
      "${inputs.reticulum-flake}/parts/media-server.nix"
    ];
    mediaServer = {
      enable=true;
      mediaPath = "/media";
      #mediaPath = "/home/${user}/media";#TODO: change to correct path/dynamic
      openFirewall = false; #use Caddy
    };
    caddyProxy = {
      enable = true;
      mode = "lan";
      tailscaleAccess = {
        enable = true;
        #access from http://<tailscale-ip>:8080
      };
    };
  };


}
