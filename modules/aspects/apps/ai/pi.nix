{inputs, den, lib, ...}:
let
  aiConfig = {
    dataDir        = "/data/ai_models";
    ollamaHost     = "127.0.0.1";
    ollamaPort     = 11434;
    tailscaleIP    = "100.x.x.x"; # replace with your microvm's tailscale IP
    tailnet_domain = "tnet.loc"; #see headscale.nix
    pi_port        = 8999; #dev port; prod port 9000
  };

  # immediate subdirectories of `dir`, as paths (pi's skills/extensions
  # options are listOf path — plain dir-name strings are rejected)
  dirPaths = dir:
    map (name: dir + "/${name}") (
      builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir dir)
      )
    );

  # pi's environment option takes tagged values: { file = …; } reads the
  # file at runtime (for sops secrets), { value = …; } is a literal.
  sopsEnv = config: {
    ANTHROPIC_API_KEY.file  = config.sops.secrets."ai_env/anthropic/api_key".path;
    DEEPSEEK_API_KEY.file   = config.sops.secrets."ai_env/deepseek/api_key".path;
    MOONSHOT_API_KEY.file   = config.sops.secrets."ai_env/kimi/api_key".path; #check
    OPENROUTER_API_KEY.file = config.sops.secrets."ai_env/openrouter/api_key".path;
  };

  common = {
    rules = ./config/BASE_PROMPT.md;
    # recursive read of directory ./config/skills
    skills = dirPaths ./config/skills;
    extensions = dirPaths ./config/extensions;

    models = ./config/models.json;
    # settings is type `attrs`, not a path — import the JSON
    settings = lib.importJSON ./config/settings.json; #https://pi.dev/docs/latest/settings
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
    ];
    nixos = {config, host, user, lib, pkgs, ...}:{    
      imports = [ inputs.pi.nixosModules.default ];

      programs.pi.coding-agent = common // {
        enable = true;

        environment = (sopsEnv config) // {
          PI_SHARE_VIEWER_URL.value = "https://pi.${host.hostName}.${aiConfig.tailnet_domain}/session/"; #magic DNS
        };

        extraArgs = [ "--mode" "rpc" "--bind" "${aiConfig.tailscaleIP}:${toString aiConfig.pi_port}" ];

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

    # inputs.pi.homeModules.default is a *home-manager* module (it sets
    # home.packages) — it belongs in the homeManager class, NOT the darwin
    # (nix-darwin system) class. Guarded to darwin so NixOS hosts don't get
    # a second pi install on top of the nixos module above.
    homeManager = {config, osConfig, user, lib, pkgs, ...}: {
      imports = [ inputs.pi.homeModules.default ];

      config = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
        programs.pi.coding-agent = common // {
          enable = true;

          # Use osConfig to reference darwin system sops paths (/run/secrets/…)
          # instead of home-manager sops paths (~/.config/sops-nix/secrets/…)
          environment = sopsEnv osConfig;

          # no jail outside linux
        };
      };
    };
  };
}
