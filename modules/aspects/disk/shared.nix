{ den, lib, ... }:
{
  # Parametric shared-folder aspect — the /data convention for the
  # mergerfs-media / nfs-media pattern.
  #
  #   (den.aspects.disk.data { dirs = [ "local" "media" ]; })
  #
  # Creates <path> and <path>/<dir>... via tmpfiles with uniform ownership.
  # Use on hosts where the shared tree lives on a plain filesystem (cool's
  # ext4 root). On ZFS hosts (boreal) prefer real datasets in the disk
  # aspect instead — tmpfiles runs at sysinit and would be shadowed by the
  # dataset mounts anyway.
  # Layout convention (uniform across hosts):
  #   /data        root:root 0755 — container only, nothing writable here
  #   /data/local  1000:100  0775 — private scratch (games, …), NOT exported
  #   /data/media  1000:100  0775 — "publish here": exported ro to the
  #                                 tailnet on peers; merged into /data/merged
  #                                 on the gateway (mergerfs), which is what
  #                                 Jellyfin scans. Publishing = mv local→media
  #                                 (same filesystem → instant rename).
  den.aspects.disk.data =
    { path ? "/data"
    , dirs ? [ "local" "media" ]
    , rootOwner ? "root"
    , rootGroup ? "root"
    , rootMode ? "0755"
    , owner ? "1000"   # avanonyme
    , group ? "100"    # users
    , dirMode ? "0775" # group-writable: drop media in from any admin user
    }:
    {
      nixos = { ... }: {
        systemd.tmpfiles.rules =
          [ "d ${path} ${rootMode} ${rootOwner} ${rootGroup} -" ]
          ++ map (d: "d ${path}/${d} ${dirMode} ${owner} ${group} -") dirs;
      };
    };
}
