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
  den.aspects.disk.data =
    { path ? "/data"
    , dirs ? [ "media" ]
    , owner ? "1000"   # avanonyme
    , group ? "100"    # users
    , dirMode ? "0775" # group-writable: drop media in from any admin user
    }:
    {
      nixos = { ... }: {
        systemd.tmpfiles.rules =
          [ "d ${path} 0755 ${owner} ${group} -" ]
          ++ map (d: "d ${path}/${d} ${dirMode} ${owner} ${group} -") dirs;
      };
    };
}
