{ inputs, ... }:
{
  flake-file.inputs.disko = {
    url = "github:nix-community/disko";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.disko-boreal = {
    nixos = { ... }: {
      imports = [ inputs.disko.nixosModules.disko ];

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
            };
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^data@blank$' || zfs snapshot data@blank";
          };
        };
      };
      boot.zfs.requestEncryptionCredentials = [ "data/encrypted" ]; # prompt for encryption credentials at boot for the encrypted dataset
      # you can decrypt it after boot using
      # zfs load-key data/encrypted
      # zfs mount data/encrypted
      # and encrypt again using
      # zfs unmount data/encrypted
      # zfs unload-key data/encrypted

      # declare 
      fileSystems."/data/game" = {
        device = "data/game";
        fsType = "zfs";
        options = [ "zfsutil" ];
      };
    };
  };
}
