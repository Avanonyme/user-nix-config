{...}:
let  aiConfig = {
    dataDir = "/data/ai_models";
    ollamaHost = "127.0.0.1";
    # Listen address for the host ollama launchd agent. 0.0.0.0 so apple
    # containers can reach it (they see the host at the vmnet gateway IP,
    # not 127.0.0.1).
    ollamaListenHost = "0.0.0.0";
    ollamaPort = 11434;
    # Host as seen from inside apple containers (vmnet NAT gateway).
    # Verify with: container run --rm alpine ip route | head -1
    #containerGatewayIP = "10.0.83.100";

    ollamaModels = [ "llama3.2" "huihui_ai/qwen3-abliterated:8b" "nomic-embed-text" ];

  };
in 
{

 den.aspects.apps.ollama = {

  nixos = {user,pkgs,...}:{
    services.ollama = {
      enable = true;
      package = pkgs.ollama-rocm;
      loadModels = aiConfig.ollamaModels;
      modelsDir = aiConfig.dataDir;

      host = aiConfig.ollamaHost;
      port = aiConfig.ollamaPort;
      #openFirewall = true; #to serve on tailnet
    };
# Scoped to ollama's own subdir — must NOT chown/chmod all of /data
# (that's a shared pool root owned 1000:100, see disk/filesystem.nix).
systemd.services.ollama-data-perms = {
  wantedBy = [ "multi-user.target" ];
  after = [ "zfs-mount.service" "data.mount" ];
  requires = [ "data.mount" ];
  before = [ "ollama.service" ];

  serviceConfig = {
    Type = "oneshot";
    RemainAfterExit = true;
  };

  script = ''
    mkdir -p ${aiConfig.dataDir}
    chown ollama:ollama ${aiConfig.dataDir}
    chmod u+rwX,go-rwx ${aiConfig.dataDir}
  '';
};
  };
 };

}