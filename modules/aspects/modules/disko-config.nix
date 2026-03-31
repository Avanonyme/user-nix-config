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
                    # LUKS passphrase will be prompted interactively only
                    type = "luks";
                    name = "crypted";
                    settings = {
                      allowDiscards = true;
                    };
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
            };
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^data@blank$' || zfs snapshot data@blank";

            datasets = {
              "encrypted" = {
                type = "zfs_fs";
                mountpoint = "/data";
                options = {
                  encryption = "aes-256-gcm";
                  keyformat = "passphrase";
                  keylocation = "file:///tmp/secret.key";
                  #echo "your-zfs-passphrase" > /tmp/zfs-key.txt to generate a passphrase
                  #nixos-anywhere \
                  #--disk-encryption-keys /tmp/secret.key /tmp/zfs-key.txt \
                  #--flake .#boreal \
                  #root@<target-ip>
                };
                # use this to read the key during boot
                postCreateHook = ''
                  zfs set keylocation="prompt" "data/encrypted";

                '';
              };
            };
          };
        };
      };
    };
  };
}
