{den, inputs, pkgs,...}:
{

  flake-file.inputs.llm-agents = {
    url ="github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.aionui.nixos = {pkgs,...}:{
      environment.systemPackages = with inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system}; [
        aionui
      ];
  };
}