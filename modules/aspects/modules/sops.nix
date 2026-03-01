{den, inputs,...}:
{
  # 1. define inputs, and add to flake.nix
  flake-file.inputs.sops-nix = {
    url = "github:mic92/sops-nix";
    inputs.nixpkgs.follows ="nixpkgs";
  };


  # following https://guekka.github.io/nixos-server-2/
  den.aspects.sops = 
  let
    isEd25519 = k: k.type == "ed25519";
    getKeyPath = k: k.path;
    keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
  in
  {
    imports = [
      sops-nix.nixosModules.sops
    ];

    sops = {
      age.sshKeyPaths = map getKeyPath keys;
    };
  };  
  #TODO: still need to configure keys
}
