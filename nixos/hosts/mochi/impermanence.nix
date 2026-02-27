{ config, lib, ... }:

let
  rootFs = config.fileSystems."/";
  btrfsDevice = rootFs.device;
  rootSnapshotRetention = 3;

  managedHomeUsers = lib.filterAttrs (
    _: user: (user.isNormalUser or false) && (user ? home) && lib.hasPrefix "/" (toString user.home)
  ) config.users.users;

  mkHomeDirTmpfilesRule =
    name: user: "d ${toString user.home} ${user.homeMode or "0700"} ${name} ${user.group or "users"} -";

  commonBtrfsMountOptions = [
    "compress=zstd"
    "noatime"
  ];
in
{
  assertions = [
    {
      assertion = rootFs.fsType == "btrfs";
      message = "mochi impermanence requires fileSystems.\"/\".fsType = \"btrfs\".";
    }
  ];

  fileSystems."/" = {
    options = [ "subvol=@root" ] ++ commonBtrfsMountOptions;
  };

  fileSystems."/nix" = {
    device = btrfsDevice;
    fsType = "btrfs";
    neededForBoot = true;
    options = [ "subvol=@nix" ] ++ commonBtrfsMountOptions;
  };

  fileSystems."/persist" = {
    device = btrfsDevice;
    fsType = "btrfs";
    neededForBoot = true;
    options = [ "subvol=@persist" ] ++ commonBtrfsMountOptions;
  };

  # Mount the persisted age key directory before stage-2 activation.
  fileSystems."/var/lib/sops-nix" = {
    device = "/persist/var/lib/sops-nix";
    fsType = "none";
    options = [
      "bind"
      "x-gvfs-hide"
    ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      "/var/log"
      "/var/lib/nixos"
      "/var/lib/systemd"
      "/var/lib/NetworkManager"
      "/var/lib/bluetooth"

      "/etc/NetworkManager/system-connections"

      {
        directory = "/var/lib/sops-nix";
        mode = "0700";
      }

      {
        directory = "/root";
        mode = "0700";
      }
    ];

    files = [
      "/etc/machine-id"
    ];
  };

  systemd.tmpfiles.rules = lib.mapAttrsToList mkHomeDirTmpfilesRule managedHomeUsers;

  boot.initrd.postDeviceCommands = lib.mkAfter /* sh */ ''
    (
      set -e

      imperm_log() {
        echo "[impermanence:initrd] $*"
      }

      imperm_error() {
        echo "[impermanence:initrd] ERROR: $*" >&2
      }

      imperm_mounted=0

      imperm_cleanup() {
        if [ "$imperm_mounted" -eq 1 ]; then
          umount /btrfs_tmp >/dev/null 2>&1 || true
        fi
      }

      imperm_dump_subvolumes() {
        if [ "$imperm_mounted" -eq 1 ]; then
          imperm_error "Current subvolumes:"
          btrfs subvolume list /btrfs_tmp >&2 || true
        fi
      }

      imperm_abort() {
        imperm_error "$*"
        imperm_dump_subvolumes
        exit 1
      }

      imperm_delete_subvolume_recursively() {
        path="$1"

        if ! imperm_is_subvolume "$path"; then
          imperm_error "Skipping missing or non-subvolume path: $path"
          return 0
        fi

        if btrfs subvolume delete -R "$path" >/dev/null 2>&1; then
          return 0
        fi

        imperm_error "Recursive delete fallback for: $path"
        subvolumes="$(btrfs subvolume list -o "$path" | cut -f 9- -d ' ' | sort -r || true)"

        old_ifs="$IFS"
        IFS=$'\n'
        for subvolume in $subvolumes; do
          [ -n "$subvolume" ] || continue
          child="/btrfs_tmp/$subvolume"
          if imperm_is_subvolume "$child"; then
            btrfs subvolume delete "$child" || imperm_abort "Failed to delete subvolume $child."
          fi
        done
        IFS="$old_ifs"

        btrfs subvolume delete "$path" || imperm_abort "Failed to delete subvolume $path."
      }

      imperm_list_root_snapshots() {
        ls -1 /btrfs_tmp/@root-history 2>/dev/null | sort || true
      }

      imperm_is_subvolume() {
        btrfs subvolume show "$1" >/dev/null 2>&1
      }

      imperm_prune_old_root_snapshots() {
        snapshots="$(imperm_list_root_snapshots)"

        old_ifs="$IFS"
        IFS=$'\n'

        snapshot_count=0
        for snapshot in $snapshots; do
          [ -n "$snapshot" ] || continue
          snapshot_count=$((snapshot_count + 1))
        done

        remove_count=$((snapshot_count - ${toString rootSnapshotRetention}))
        if [ "$remove_count" -le 0 ]; then
          IFS="$old_ifs"
          return 0
        fi

        for snapshot in $snapshots; do
          [ -n "$snapshot" ] || continue
          if [ "$remove_count" -le 0 ]; then
            break
          fi

          snapshot_path="/btrfs_tmp/@root-history/$snapshot"
          if ! imperm_is_subvolume "$snapshot_path"; then
            imperm_error "Skipping non-subvolume entry: $snapshot_path"
            continue
          fi

          imperm_log "Pruning old root snapshot: $snapshot"
          if (imperm_delete_subvolume_recursively "$snapshot_path"); then
            remove_count=$((remove_count - 1))
          else
            imperm_error "Failed to prune snapshot, continuing boot: $snapshot_path"
          fi
        done

        IFS="$old_ifs"
      }

      trap imperm_cleanup EXIT

      mkdir -p /btrfs_tmp
      mount -t btrfs -o subvolid=5 "${btrfsDevice}" /btrfs_tmp || imperm_abort "Failed to mount btrfs top-level."
      imperm_mounted=1
      imperm_log "Mounted btrfs top-level on /btrfs_tmp."

      if [ ! -d /btrfs_tmp/@nix ] || [ ! -d /btrfs_tmp/@persist ]; then
        imperm_abort "Missing @nix or @persist subvolume; run the impermanence bootstrap first."
      fi
      imperm_log "Verified @nix and @persist subvolumes."

      if [ ! -d /btrfs_tmp/@root-blank ]; then
        imperm_log "Creating @root-blank baseline subvolume."
        btrfs subvolume create /btrfs_tmp/@root-blank || imperm_abort "Failed to create @root-blank."
        mkdir -p /btrfs_tmp/@root-blank/boot
        mkdir -p /btrfs_tmp/@root-blank/etc
        mkdir -p /btrfs_tmp/@root-blank/home
        mkdir -p /btrfs_tmp/@root-blank/nix
        mkdir -p /btrfs_tmp/@root-blank/persist
        mkdir -p /btrfs_tmp/@root-blank/root
        mkdir -p /btrfs_tmp/@root-blank/tmp
        mkdir -p /btrfs_tmp/@root-blank/var
        chmod 1777 /btrfs_tmp/@root-blank/tmp
        btrfs property set -ts /btrfs_tmp/@root-blank ro true || imperm_abort "Failed to make @root-blank read-only."
      fi

      mkdir -p /btrfs_tmp/@root-history
      if [ -d /btrfs_tmp/@root ]; then
        root_snapshot_name="$(date -u +%Y%m%d-%H%M%S)"
        root_snapshot_path="/btrfs_tmp/@root-history/$root_snapshot_name"
        if [ -e "$root_snapshot_path" ]; then
          root_snapshot_path="$root_snapshot_path-$$"
        fi

        imperm_log "Archiving existing @root to $root_snapshot_path."
        mv /btrfs_tmp/@root "$root_snapshot_path" || imperm_abort "Failed to archive @root."
        imperm_prune_old_root_snapshots
      fi

      imperm_log "Recreating @root from @root-blank."
      btrfs subvolume snapshot /btrfs_tmp/@root-blank /btrfs_tmp/@root || imperm_abort "Failed to snapshot @root-blank to @root."

      umount /btrfs_tmp || imperm_abort "Failed to unmount /btrfs_tmp."
      imperm_mounted=0
      imperm_log "Impermanence initrd reset completed."
    ) || exit 1
  '';
}
