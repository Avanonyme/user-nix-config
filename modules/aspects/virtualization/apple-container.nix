{den,...}:{

#https://github.com/halfwhey/nix-apple-container

#Recursivity is everywhere
flake-file.inputs = {
    # Follow master — picks up nix-builder image updates automatically:
    nix-apple-container.url = "github:halfwhey/nix-apple-container";
    # Pin to a release for stability:
    # nix-apple-container.url = "github:halfwhey/nix-apple-container/v0.0.6";

    nix-apple-container.inputs.nixpkgs.follows = "nixpkgs";
  };

den.aspects.apple-container = {inputs,...}:{
  imports = [ inputs.nix-apple-container.darwinModules.default ];
  darwin.services.containerization.enable = true;

  
  #Exameple:Web server with port forwarding
  web_serve.darwin = {
    services.containerization = {
      containers.nginx = {
        image = "nginx:alpine";
        autoStart = true;
        extraArgs = [ "--publish" "8080:80" ];
      };
    };
  };
  #Example: Gitea with persistent storage
  gitea_serve.darwin = {
    services.containerization = {
      containers.gitea = {
        image = "gitea/gitea:latest";
        autoStart = true;
        volumes = [
          "/Users/me/.gitea/data:/data"
        ];
        extraArgs = [
          "--publish" "3000:3000"
          "--publish" "2222:22"
        ];
      };
    };
  };

};
}