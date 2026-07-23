{ den, lib, ... }:
{
  # Jellyfin runs as a podman OCI container, exposed on the tailnet only via
  # `tailscale serve` (den.provides.tailscale-serve) — no nginx, no public
  # domain. Reachable at https://<host>.<tailnet_domain> (e.g. https://cool.tnet.loc).
  #
  # NOTE: settings must be a plain attrset — the schema walker in
  # modules/schema/host.nix inspects den.aspects statically and cannot apply
  # functions. Derived defaults (from networking.domain / headscale settings)
  # are resolved in the nixos block below, where `host` is legitimately in scope.
  den.aspects.services.jellyfin = {
    includes = with den.aspects; [
      podman

      # Expose the container's localhost port on the tailnet.
      # Keep `port` in sync with settings.services.jellyfin.jellyfinPort if
      # you ever override it on a host (includes are static — they can't read
      # host settings).
      (den.provides.tailscale-serve { port = 8096; afterUnits = [ "podman-jellyfin.service" ]; })
    ];

    settings = {
      jellyfinDomain = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = "Public URL host for jellyfin. Defaults to <hostname>.<tailnet_domain> (MagicDNS) when null — a service subdomain like jelly.tnet.loc does NOT resolve under headscale MagicDNS and gets no serve certificate.";
      };
      jellyfinPort = lib.mkOption {
        type = lib.types.port;
        default = 8096;
        description = "Host-side (localhost) port the container is published on (default 8096)";
      };
      imageTag = lib.mkOption {
        type = lib.types.str;
        default = "10.11";
        description = "Tag of docker.io/jellyfin/jellyfin to run";
      };
      mediaDir = lib.mkOption {
        type = lib.types.str;
        default = "/var/lib/jellyfin/media";
        description = "Host directory with media, bind-mounted read-only at /media";
      };
      timezone = lib.mkOption {
        type = lib.types.str;
        default = "UTC";
        description = "TZ inside the container (affects library scan scheduling, etc.)";
      };
      disableVideoTranscoding = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Disable video transcoding for all users while keeping audio
          transcoding (cheap, often needed for codec compatibility).
          Enforced declaratively via a oneshot unit that patches every user's
          UserPolicy through the Jellyfin API (EnableVideoPlaybackTranscoding=false,
          EnableAudioPlaybackTranscoding=true).

          Bootstrap (chicken-and-egg: the key can only be created once
          Jellyfin is up):
            1. Rebuild, finish the setup wizard at https://<host>.<tailnet>
            2. Dashboard -> API Keys -> create one
            3. sudo install -m 0400 /dev/stdin /var/lib/jellyfin/api_key
               (paste the key, Ctrl-D)
            4. systemctl start jellyfin-enforce-transcode-policy (or reboot)
          Until the keyfile exists the oneshot is a graceful no-op.
        '';
      };
    };

    nixos =
      { host, lib, pkgs, ... }:
      let
        cfg = host.settings.services.jellyfin;
        tailnetDomain = host.settings.networking.headscale.tailnet_domain;
        jellyfinDomain =
          if cfg.jellyfinDomain != null
          then cfg.jellyfinDomain
          else "${host.hostName}.${tailnetDomain}";
        jellyfinPort = cfg.jellyfinPort;

        enforcePolicy = pkgs.writeShellApplication {
          name = "jellyfin-enforce-transcode-policy";
          # key="$(cat "${config.sops.secrets."jellyfin/api_key".path}")"
          runtimeInputs = [ pkgs.curl pkgs.jq ];
          text = ''
            set -eu
            url="http://127.0.0.1:${toString jellyfinPort}"
            keyfile=/var/lib/jellyfin/api_key

            if [ ! -r "$keyfile" ]; then
              echo "jellyfin: $keyfile missing — create an API key in the dashboard"
              echo "and install it there (mode 0400); see services/jellyfin.nix. No-op."
              exit 0
            fi
            key="$(cat "$keyfile")"

            # Wait for the API (container may still be initializing)
            for _ in $(seq 1 60); do
              curl -fsS -H "X-Emby-Token: $key" "$url/System/Info" >/dev/null 2>&1 && break
              sleep 4
            done

            # Patch every user's policy: video transcoding off, audio stays on.
            # GET the full user object so the POST preserves all other fields.
            curl -fsS -H "X-Emby-Token: $key" "$url/Users" | jq -r '.[].Id' | while read -r uid; do
              curl -fsS -H "X-Emby-Token: $key" "$url/Users/$uid" \
                | jq '.Policy.EnableVideoPlaybackTranscoding = false
                    | .Policy.EnableAudioPlaybackTranscoding = true
                    | .Policy' \
                | curl -fsS -X POST -H "X-Emby-Token: $key" \
                    -H "Content-Type: application/json" -d @- \
                    "$url/Users/$uid/Policy" >/dev/null
              echo "patched policy for user $uid"
            done
          '';
        };
      in
      {
        virtualisation.oci-containers.containers.jellyfin = {
          image = "docker.io/jellyfin/jellyfin:${cfg.imageTag}";
          autoStart = true;

          # Only published on localhost — tailscale serve proxies tailnet
          # traffic to it.
          ports = [ "127.0.0.1:${toString jellyfinPort}:8096" ];

          # Named volumes are auto-created by podman and survive rebuilds.
          # The media dir is a host bind-mount, read-only.
          volumes = [
            "jellyfin-config:/config"
            "jellyfin-cache:/cache"
            "${cfg.mediaDir}:/media:ro"
          ];

          environment = {
            TZ = cfg.timezone;
            # Advertise the tailnet URL so clients/DLNA generate correct links
            JELLYFIN_PublishedServerUrl = "https://${jellyfinDomain}";
          };
        };

        # Enforce per-user transcoding policy after each (re)start:
        # video transcoding OFF (cool has no GPU — software video transcode
        # is CPU-bound), audio transcoding ON (cheap, needed for codec compat).
        # Idempotent; re-applies on boot so users created later get patched too.
        systemd.services.jellyfin-enforce-transcode-policy = lib.mkIf cfg.disableVideoTranscoding {
          description = "Disable video transcoding (keep audio) for all Jellyfin users";
          after = [ "podman-jellyfin.service" ];
          requires = [ "podman-jellyfin.service" ];
          wantedBy = [ "multi-user.target" ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${enforcePolicy}/bin/jellyfin-enforce-transcode-policy";
          };
        };
      };
  };
}
