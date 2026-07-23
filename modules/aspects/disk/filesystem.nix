{ den, inputs, lib,... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.disk.boreal = {
    nixos = { ... }: {
      imports = [ inputs.disko.nixosModules.disko ];

      boot.supportedFilesystems = [ "zfs" ];
      boot.initrd.supportedFilesystems = [ "zfs" ];
      #boot.zfs.extraPools = [ "data" ]; # import non-root ZFS pool at boot
      

      boot.zfs.forceImportRoot = true; #silences the warning: evaluation warning: `boot.zfs.forceImportRoot` is using the default value of `true`. It is highly recommended to set it to `false`, the new default from 26.11 on, to reduce the risk of data loss. Alternatively, you can silence this warning by explicitly setting it to `true`.
      disko.devices.disk.root.device = "/dev/sdb";
      disko.devices.disk.data1.device = "/dev/sda";
      disko.devices.disk.data2.device = "/dev/sdc";
      # declare file systems for boreal

       # prompt for encryption credentials at boot for the encrypted dataset
      #boot.zfs.requestEncryptionCredentials = [ "data/encrypted" ];
      # you can decrypt it after boot using
      # zfs load-key data/encrypted
      # zfs mount data/encrypted
      # and encrypt again using
      # zfs unmount data/encrypted
      # zfs unload-key data/encrypted
      
      #fileSystems."/data/encrypted" = {
      # device = "data/encrypted";
      #  fsType = "zfs";
      #  options = [ "zfsutil" ];
      #};

      disko.devices = {
        disk = {
          root = {
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                ESP = {
                  size = "1G";
                  type = "EF00";
                  content = {
                    type = "filesystem";
                    format = "vfat";
                    mountpoint = "/boot";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                swap = {
                  size = "4G";
                  content = {
                    type = "swap";
                    priority = 100;
                  };
                };
                root = {
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "ext4";
                    mountpoint = "/";

                  };
                };
              };
            };
          };
          data1 = {
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "data";
                  };
                };
              };
            };
          };
          data2 = {
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                zfs = {
                  size = "100%";
                  content = {
                    type = "zfs";
                    pool = "data";
                  };
                };
              };
            };
          };
        };
        zpool = {
          data = {
            type = "zpool";
            mode = "mirror";
            rootFsOptions = {
              compression = "zstd";
              # Media-dominated pool: big records, no atime. Inherited by
              # everything (including /data/local and /data/media, which are
              # plain directories — see below).
              # NOTE: /data/local also holds games (many small files, random
              # reads). That's fine here: small files still use small blocks
              # (recordsize is a MAX), and atime=off helps game loads too.
              # If game I/O ever feels zstd-CPU-bound, the no-rebuild escape
              # hatch is: zfs set compression=lz4 data  (applies to new writes).
              recordsize = "1M";
              atime = "off";
              "com.sun:auto-snapshot" = "true";
              mountpoint = "legacy"; # mounted via fileSystems in boreal.nix, not ZFS auto-mount
            };
            datasets = {
              encrypted = {
                type = "zfs_fs";
                options = {
                  encryption = "aes-256-gcm";
                  keyformat = "passphrase";
                  keylocation = "prompt";
                  compression = "zstd";
                  mountpoint = "legacy";
                };
              };
              # NOTE: /data/local and /data/media are deliberately PLAIN
              # DIRECTORIES on the pool root, not datasets — publishing is
              # `mv /data/local/x /data/media/`, and cross-dataset moves are
              # copy+delete (separate filesystems), which for multi-GB media
              # defeats the whole workflow. Same fs = instant rename.
            };
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^data@blank$' || zfs snapshot data@blank";
          };
        };
      };
    # Mount the pool root at /data (the shared-folder convention used by
    # disk.data / nfs-media / mergerfs-media) — dataset mountpoints are
    # legacy, so mounts are declared here, not by ZFS automount.
    fileSystems."/data" = {
      device = "data";
      fsType = "zfs";
      options = ["zfsutil" "nofail"];
    };
    # Non-recursive, roots only. Runs after the pool is mounted because the
    # dirs live ON the pool (tmpfiles at sysinit would be shadowed by the
    # mount). /data stays root:root 0755 (pure container); both branches are
    # user-writable — /data/local is private, /data/media is the published
    # channel that nfs-media.peer exports ro to the tailnet.
    systemd.services.fix-data-perms = {
      wantedBy = [ "multi-user.target" ];
      after = [ "zfs-mount.service" "data.mount" ];
      serviceConfig.Type = "oneshot";
      script = ''
        chown root:root /data && chmod 0755 /data
        mkdir -p /data/local /data/media
        chown 1000:100 /data/local /data/media
        chmod 0775 /data/local /data/media
      '';
    };


    nix = {    
      # do garbage collection weekly to keep disk usage low
      gc = {
        automatic = lib.mkDefault true;
        options = lib.mkDefault "--delete-older-than 7d";
      };
      settings = {
        # Disable auto-optimise-store because of this issue:
        #   https://github.com/NixOS/nix/issues/7273
        # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
        auto-optimise-store = false;
      };
    };
    
    };

  };

  den.aspects.disk.cool = {
    # /data/local = private scratch (games, …), /data/media = cool's own
    # published branch (both user-writable). /data/merged is the mergerfs
    # mountpoint — auto-created by the fileSystems entry when
    # test/mergerfs-media.nix is wired, no tmpfiles line needed.
    includes = [
      (den.aspects.disk.data { dirs = [ "local" "media" ]; })
    ];

    nixos = {
    imports = [ inputs.disko.nixosModules.disko ];

    disko.devices = {
      disk.main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            swap = {
              size = "4G";
              content = {
                type = "swap";
                priority = 100;
              };
            };
            ESP = {
              type = "EF00";
              size = "1G";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = ["umask=0077"];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
    };
  };
}
