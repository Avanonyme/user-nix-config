{ den, inputs, ... }:{
  flake-file.inputs = {
    microvm = {
      url = "github:astro/microvm.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
  den.provides.microvm-integration = {
    imports = [
    (import "${inputs.den}/templates/microvm/modules/microvm-integration.nix")
    ];
  };
}