# ipfs-media.nix
# deentralized NAS storage in shared /data for tailnet with headscale
# ──────────────────────────────────────────────
# den.aspect: P2P media sharing across a trusted tailnet, surfaced through
# the existing nixflix/Jellyfin UI.
#
#   Friends keep their media on THEIR OWN machines (peers). Each peer runs an
#   IPFS node (kubo) that pins its media and publishes a stable IPNS name.
#   A gateway node (cool) runs kubo as a caching relay AND hosts Jellyfin.
#
#   Crucially: only TINY pointer files ever travel to cool.
#     - Peer runs `ipfs add` on each media file  → gets a content ID (CID)
#     - Peer writes a Jellyfin `.strm` file (a one-line text file holding a
#       stream URL pointing at cool's IPFS gateway for that CID)
#     - Peer rsyncs only the .strm/.nfo/poster files to cool over the tailnet
#   Jellyfin on cool scans a LOCAL catalog → scans are instant and never hang
#   on a dead peer (the FUSE-mount failure mode is avoided entirely).
#   At PLAYBACK, cool's gateway resolves the CID, fetches bytes from whichever
#   peers are online via the IPFS swarm, and caches them. cool therefore stores
#   only kilobytes of catalog + a hot cache — cold content stays distributed.
#
#   Resilience model: many small nodes on one tailnet. If a peer is offline,
#   only ITS uncached titles are temporarily unplayable; everything else works.
#   cool's paid/always-on tier buys transcoding + hot-cache + relay speed, i.e.
#   it makes cold-fetch fast — it is a convenience layer over a P2P base, not
#   the base itself.
#
# ROLES (den `provides` subaspects)
#   den.aspects.ipfs-media._.peer      → on each user's source machine
#   den.aspects.ipfs-media._.gateway   → on cool (alongside nixflix/Jellyfin)
#
# ──────────────────────────────────────────────
# WIRING
#
#   1. Peer machine (e.g. boreal.nix includes):
#        den.aspects.ipfs-media._.peer
#
#   2. Gateway machine (cool.nix includes), next to the media-server aspect:
#        den.aspects.ipfs-media._.gateway
#      ⚠ DEFERRED: cool has no hardware yet and the tailnet isn't up. The
#        gateway include is commented out in cool.nix until both exist.
#
#   3. Register the peer's SSH push key in sops (secrets.yaml):
#        ipfs_media_peer_ssh_key: |
#          -----BEGIN OPENSSH PRIVATE KEY-----
#          ...
#      The matching PUBLIC key (not secret) goes in the gateway's
#      users.users.${catalogUser}.openssh.authorizedKeys.keys.
#
#   4. Point the existing nixflix Jellyfin library at the catalog dir:
#        catalogDir below (default /var/lib/ipfs-catalog) — add it as a
#        Jellyfin "Movies"/"Shows" library with .strm support enabled.
#
# ──────────────────────────────────────────────
# TUNABLES — edit the let-block below per deployment.
# ──────────────────────────────────────────────

{ den, inputs, config, lib, ... }:

let
  # ── Network / ports ──────────────────────────────────────────────────────
  # kubo HTTP gateway: where .strm URLs point and where Jellyfin fetches bytes.
  # Bound to localhost on the gateway; Jellyfin fetches server-side so this is
  # reachable without exposing the gateway publicly.
  gatewayPort = 8081;
  # kubo swarm (peer-to-peer transport). Reachable over the tailnet only —
  # the headscale client aspect already trusts tailscale0, so we do NOT open
  # this port publicly.
  swarmPort = 4001;
  # kubo admin API — localhost only, never exposed.
  apiPort = 5001;

  # ── Catalog ──────────────────────────────────────────────────────────────
  # Where the tiny pointer files (.strm/.nfo/posters) live on the GATEWAY.
  # Point the nixflix Jellyfin library here.
  catalogDir = "/var/lib/ipfs-catalog";
  # Unix user that owns the catalog on the gateway and receives rsync pushes.
  catalogUser = "ipfs-catalog";

  # ── Peer source ────────────────────────────────────────────────────────-─
  # Directory on the PEER whose contents get pinned + published.
  peerMediaDir = "/data/media";
  # Gateway host as reachable over the tailnet (MagicDNS name or tailnet IP).
  # Used both for the .strm URLs and for the catalog rsync target.
  gatewayHost = "cool";

  # ── Peer identity ────────────────────────────────────────────────────────
  # The den user the publish service runs as (owns peerMediaDir, holds the
  # sops SSH key). TODO(point 5): replace with per-host den metadata that
  # declares user + tailscale IP, so this isn't hardcoded per deployment.
  peerUser = "avanonyme";
in
{
  den.aspects.ipfs-media = {

    # ══════════════════════════════════════════════════════════════════════
    # PEER — runs on each trusted user's source machine
    # ══════════════════════════════════════════════════════════════════════
    peer = {
      nixos = { pkgs, lib, config, ... }: {

        # ── Secret: SSH key for pushing the catalog to the gateway ────────-─
        # "Use sops for everything": the private key the peer authenticates
        # with lives in sops, owned by the den user so the publish service
        # (which runs as that user) can read it. The matching PUBLIC key is not
        # secret — it goes in the gateway's authorizedKeys as plaintext.
        # Register the value in secrets.yaml under key: ipfs_media_peer_ssh_key
        sops.secrets."ipfs-media/peer_ssh_key" = {
          #owner = peerUser;
        };

        # ── kubo (IPFS) daemon ───────────────────────────────────────────-─
        services.kubo = {
          enable = true;
          # Open IPFS data dir perms so the publish/add hook (run as the media
          # user) can drive the daemon via the local API.
          dataDir = "/var/lib/ipfs";
          localDiscovery = true; # mDNS — helps peers on the same LAN find each other fast
          settings = {
            Addresses = {
              API = "/ip4/127.0.0.1/tcp/${toString apiPort}";
              Gateway = "/ip4/127.0.0.1/tcp/${toString gatewayPort}";
              Swarm = [
                "/ip4/0.0.0.0/tcp/${toString swarmPort}"
                "/ip6/::/tcp/${toString swarmPort}"
              ];
            };
            # Keep pinned media; don't garbage-collect what we publish.
            Datastore.GCPeriod = "24h";
          };
        };

        # ── Pin the media dir + publish an IPNS name on change ────────────-─
        # systemd.path watches the media dir; the service re-adds the tree,
        # pins it, republishes IPNS, regenerates .strm pointers, and pushes the
        # (tiny) catalog to the gateway over SSH.
        systemd.paths."ipfs-media-publish" = {
          wantedBy = [ "multi-user.target" ];
          pathConfig = {
            PathModified = peerMediaDir;
            Unit = "ipfs-media-publish.service";
          };
        };

        systemd.services."ipfs-media-publish" = {
          description = "Pin media to IPFS, publish IPNS, push .strm catalog to gateway";
          after = [ "ipfs.service" "network-online.target" ];
          wants = [ "network-online.target" ];
          path = with pkgs; [ kubo jq openssh rsync coreutils findutils gnused ];
          serviceConfig = {
            Type = "oneshot";
            # Runs as the den user that owns peerMediaDir and whose sops SSH
            # key authenticates the catalog push to the gateway.
            User = peerUser; # user.userName
            Environment = [
              "IPFS_PATH=/var/lib/ipfs"
              "IPFS_API=/ip4/127.0.0.1/tcp/${toString apiPort}"
            ];
          };
          script = ''
            set -euo pipefail

            MEDIA_DIR="${peerMediaDir}"
            WORK="$(mktemp -d)"
            trap 'rm -rf "$WORK"' EXIT
            PEER_NAME="$(hostname)"
            CATALOG_STAGE="$WORK/catalog/$PEER_NAME"
            mkdir -p "$CATALOG_STAGE"

            # 1. Add + pin the whole media tree, get the root CID.
            ROOT_CID="$(ipfs add -Q -r --pin "$MEDIA_DIR")"
            echo "Pinned $MEDIA_DIR as $ROOT_CID"

            # 2. Publish a stable IPNS name pointing at the root (best effort).
            ipfs name publish --allow-offline "/ipfs/$ROOT_CID" || \
              echo "IPNS publish deferred (offline)"

            # 3. For every media file, resolve its CID and emit a .strm pointer.
            #    The URL targets the GATEWAY's IPFS gateway; Jellyfin on the
            #    gateway fetches server-side and the swarm sources the bytes.
            find "$MEDIA_DIR" -type f \
              \( -iname '*.mkv' -o -iname '*.mp4' -o -iname '*.avi' \
                 -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.webm' \) \
              -print0 | while IFS= read -r -d "" f; do
                REL="''${f#$MEDIA_DIR/}"
                CID="$(ipfs add -Q --only-hash "$f")"
                OUT="$CATALOG_STAGE/$REL"
                mkdir -p "$(dirname "$OUT")"
                # .strm is a one-line file Jellyfin treats as a streamable source
                echo "http://${gatewayHost}:${toString gatewayPort}/ipfs/$CID" \
                  > "''${OUT%.*}.strm"
              done

            # 4. Push only the tiny pointer files to the gateway over the tailnet.
            #    Authenticates with the sops-managed private key.
            rsync -az --delete \
              -e "ssh -i ${config.sops.secrets."ipfs-media/peer_ssh_key".path} -o StrictHostKeyChecking=accept-new" \
              "$WORK/catalog/$PEER_NAME/" \
              "${catalogUser}@${gatewayHost}:${catalogDir}/$PEER_NAME/"

            echo "Catalog pushed for $PEER_NAME"
          '';
        };
      };
    };

    # ══════════════════════════════════════════════════════════════════════
    # GATEWAY — runs on cool, alongside the nixflix/Jellyfin media-server
    # ══════════════════════════════════════════════════════════════════════
    gateway = {
      nixos = { pkgs, lib, config, ... }: {

        # ── kubo as a caching relay ──────────────────────────────────────-─
        services.kubo = {
          enable = true;
          dataDir = "/var/lib/ipfs";
          localDiscovery = true;
          settings = {
            Addresses = {
              API = "/ip4/127.0.0.1/tcp/${toString apiPort}";
              # Gateway on localhost — Jellyfin fetches server-side from here.
              Gateway = "/ip4/127.0.0.1/tcp/${toString gatewayPort}";
              Swarm = [
                "/ip4/0.0.0.0/tcp/${toString swarmPort}"
                "/ip6/::/tcp/${toString swarmPort}"
              ];
            };
            # Relay/cache: let GC reclaim cold cache so storage stays bounded.
            # Pinned-on-peer content is re-fetchable, so the gateway only needs
            # to hold the hot working set.
            Datastore.GCPeriod = "1h";
          };
        };
        # Periodic GC keeps the cache from growing without bound.
        services.kubo.autoMigrate = true;

        # ── Catalog landing zone for peer rsync pushes ───────────────────-─
        users.users.${catalogUser} = {
          isSystemUser = true;
          group = catalogUser;
          home = catalogDir;
          createHome = true;
          shell = pkgs.bashInteractive; # rsync-over-ssh needs a real shell
          # Authorize each peer's push key here:
          # openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA... peer@boreal" ];
        };
        users.groups.${catalogUser} = {};

        # Make the catalog readable by Jellyfin (nixflix runs jellyfin as the
        # `jellyfin` user). Group-read is enough for .strm/.nfo/posters.
        systemd.tmpfiles.rules = [
          "d ${catalogDir} 0755 ${catalogUser} ${catalogUser} -"
        ];

        # NOTE: add ${catalogDir} as a Jellyfin library (Movies/Shows) with
        # .strm support enabled. With nixflix that means pointing a library
        # path here; see media-server.nix.
      };
    };
  };
}
