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
      enableTranscoding = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to allow transcoding. When false, JELLYFIN_FFMPEG is set to /bin/false so any transcode attempt fails — clients must direct-play.";
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
          } // lib.optionalAttrs (!cfg.enableTranscoding) {
            JELLYFIN_FFMPEG = "/bin/false";
          };

          # Hardware transcoding (VA-API/QSV): enable on hosts with /dev/dri
          # (not needed on cool, no GPU). e.g.:
          # extraOptions = [ "--device=/dev/dri" ];
        };
      };
  };
}
