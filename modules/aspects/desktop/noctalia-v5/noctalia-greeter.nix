{ inputs, ... }: {
  # https://github.com/noctalia-dev/noctalia-greeter
  flake-file.inputs = {
    noctalia-greeter = {
      url = "github:noctalia-dev/noctalia-greeter";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  den.aspects.desktop.noctalia-greeter = {
    nixos = { pkgs, ... }: {
      imports = [ inputs.noctalia-greeter.nixosModules.default ];

      programs.noctalia-greeter = {
        enable = true;

        greeter-args = "--session Niri";
        settings.keyboard = {
          layout = "us";
        };
      };
    };
  };
}