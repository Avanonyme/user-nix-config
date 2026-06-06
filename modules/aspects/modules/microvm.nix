    { den, inputs, ... }:{
      flake-file.inputs = {
        microvm = {
          url = "github:astro/microvm.nix";
          inputs.nixpkgs.follows = "nixpkgs";
        };
      };
    #Activation — import microvm integration as a top-level module
      imports = [
        (import "${inputs.den}/templates/microvm/modules/microvm-integration.nix")
        (import "${inputs.den}/templates/microvm/modules/microvm-runners.nix")
      ];
    }
    
