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
              mountpoint = "none";
            };
            postCreateHook = "zfs list -t snapshot -H -o name | grep -E '^data@blank$' || zfs snapshot data@blank";

            datasets = {
              "main" = {
                type = "zfs_fs";
                mountpoint = "/data";
                options.mountpoint = "legacy";
                # no data encryption needed for boreal, it is a public machine, 
                # but this is how you would set it up with disko
                #options = {
                #  encryption = "aes-256-gcm";
                #  keyformat = "passphrase";
                #  keylocation = "file:///tmp/secret.key";
                #  #echo "your-zfs-passphrase" > /tmp/secret.key 
                #  #nixos-anywhere \
                #  #--disk-encryption-keys /tmp/secret.key /tmp/secret.key \ # <remote-host> <local-host>, local applied on remote
                #  #--flake .#boreal \
                #  #root@<target-ip> # run ip addr
                #};
                # use this to read the key during boot
                # postCreateHook = ''
                #   zfs set keylocation="prompt" "data/encrypted";
                # '';
              };
            };
          };
        };
      };
    };
  };
}
