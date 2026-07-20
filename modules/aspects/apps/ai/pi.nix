{inputs, den, ...}:
let
  aiConfig = {
    dataDir        = "/data/ai_models";
    ollamaHost     = "127.0.0.1";
    ollamaPort     = 11434;
    tailscaleIP    = "100.x.x.x"; # replace with your microvm's tailscale IP
    tailnet_domain = "tnet.loc"; #see headscale.nix
    pi_port        = 8999; #dev port; prod port 9000
  };
in
{
  #https://github.com/lukasl-dev/pi.nix
  flake-file.inputs.pi = {
    url = "github:lukasl-dev/pi.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.apps.pi = {
    includes = with den.aspects; [
      security.sops
      #services.ollama
      #apps.ai-UIs.full
      #etc.
    ];
    nixos = {config, host, user, home, lib, ...}:{    
      imports = [ inputs.pi.nixosModules.default ];

      programs.pi.coding-agent = {
        enable = true;
        rules = ./config/BASE_PROMPT.md;
        # skills = [ ./skills/my-skill ];
        skills = builtins.attrNames (
          lib.filterAttrs (_: type: type == "directory")
            (builtins.readDir ./config/skills)
        );
        # extensions = [ ./extensions/my-extension.ts ];
        extensions = builtins.attrNames (
          lib.filterAttrs (_: type: type == "directory")
            (builtins.readDir ./config/extensions)
        );
        
        models = ./config/models.json;
        settings = ./config/settings.json; #https://pi.dev/docs/latest/settings



        extraArgs = [ "--mode" "rpc" "--bind" "${aiConfig.tailscaleIP}:${aiConfig.pi_port}" ];
        environment = {
            ANTHROPIC_API_KEY  = config.sops.secrets."ai_env/anthropic/api_key".path;
            DEEPSEEK_API_KEY   = config.sops.secrets."ai_env/deepseek/api_key".path;
            KIMI_API_KEY       = config.sops.secrets."ai_env/kimi/api_key".path;
            OPENROUTER_API_KEY = config.sops.secrets."ai_env/openrouter/api_key".path;

            PI_SHARE_VIEWER_URL = "https://pi.${host.hostName}.${aiConfig.tailnet_domain}/session/"; #magic DNS
        };

        jail.enable = true;
        jail.permissions = combinators: with combinators; [
          # Keep the default capabilities when replacing the permission list.
          network
          mount-cwd

          # Add custom tools and their runtime closures to the jailed PATH.
          (add-pkg-deps [
            pkgs.python3
          ])          
        ];
      };

    };
  };
}