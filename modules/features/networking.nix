{inputs, ...}:
{
 flake-file.inputs.reticulum-flake = {
   url = "https://codeberg.org/adingbatponder/reticulum_nixos_flake.git";
   inputs.nixpkgs.follows = "nixpkgs";
 };

  den._.network = {
    flake-file.inputs.reticulum-flake.options.primaryUser = "tux";
  } 



}
