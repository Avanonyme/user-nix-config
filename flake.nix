{
 description = "My first flake";
 
 inputs = {
  nixpkgs = {
   url = "github:NixOS/nixpkgs/nixos-25.05";
  };
  stylix.url = "github:danth/stylix";

  home-manager.url = "github:nix-community/home-manager/release-25.05";
  home-manager.inputs.nixpkgs.follows = "nixpkgs";
 };
 
 outputs = { self, nixpkgs, home-manager, ...}:
  let 
   lib = nixpkgs.lib;
   system = "x86_64-linux";
   pkgs= nixpkgs.legacyPackages.${system};
  in {
  nixosConfigurations = {
   nixos  = lib.nixosSystem{
   inherit system;
   modules = [
     ./configuration.nix
     inputs.stylix.nixosModule.stylix
   
   ];
  };  
 };
  homeConfigurations = {
    avanonyme  = home-manager.lib.homeManagerConfiguration{
    inherit pkgs;
    modules = [ ./users/avanonyme/home.nix ];
   };};};
}
