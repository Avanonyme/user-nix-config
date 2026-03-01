{den.inputs,...}:
{
  # 1. define inputs, and add to flake.nix
  flake-file.inputs.zen-browser = {
    url = "github:0xc000022070/zen-browser-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  flake-file.inputs.firefox-addons = {
    url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.zen-browser = {
    nixos = {pkgs,...}: {
      imports = [inputs.zen-browser.nixosModules.twilight];
      programs.zen-browser.enable = true;
    };
    homeManager = {pkgs,...}: 
    let
      system = pkgs.stdenv.hostPlatform.system;
      addons = inputs.firefox-addons.packages.${system};
    in 
    {
      imports = [inputs.zen-browser.homeModules.twilight];
      programs.zen-browser = {
      
        enable = true;

        policies = {
          AutofillAddressEnabled = false;
          AutofillCreditCardEnabled = false;
          DisableAppUpdate = true;
          DisableFeedbackCommands = true;
          DisableFirefoxStudies = true;
          DisablePocket = true;
          DisableTelemetry = true;
          NoDefaultBookmarks = true;
          OfferToSaveLogins = false;
          EnableTrackingProtection = {
            Value = true;
            Locked = true;
            Cryptomining = true;
            Fingerprinting = true;
          };
          Cookies.Behavior = "reject-tracker-and-partition-foreign";
      };

      profiles."default" = {
        containersForce=true;
        extensions.packages = with addons; [
          uBlockOrigin
          Decentraleyes
          DarkReader
          CookieAutoDelete
          censor-tracker
          dearrow
          proton-vpn
          bitwarden
          unpaywall 
          zen-internet
          zotero-connector
          youtube-recommended-video
        ];

      };
    };
  };
 };
}
