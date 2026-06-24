{den, pkgs,...}:{
# following https://bkiran.com/blog/deploying-containers-nixos

  den.aspects.podman = 
  {  
    virtualisation = {
      containers.enable = true;
      podman = {
        enable = true;
        dockerCompat = true;
      };
    };
    # Useful other development tools
    environment.systemPackages = with pkgs; [
      dive # look into docker image layers
      podman-tui # status of containers in the terminal
      docker-compose # start group of containers for dev
      #podman-compose # start group of containers for dev
    ];
  };
}