{ config, lib, ... }:

let
  cfg = config.dotnix.impermanence;

  rootFs = config.fileSystems."/";

  managedHomeUsers = lib.filterAttrs (
    _: user: (user.isNormalUser or false) && (user ? home) && lib.hasPrefix "/" (toString user.home)
  ) config.users.users;

  mkHomeDirTmpfilesRule =
    name: user: "d ${toString user.home} ${user.homeMode or "0700"} ${name} ${user.group or "users"} -";

  mkPersistencePaths =
    persistence:
    if persistence == null || !(persistence.enable or true) then
      {
        directories = [ ];
        files = [ ];
      }
    else
      {
        directories = map (entry: toString entry.dirPath) persistence.directories;
        files = map (entry: toString entry.filePath) persistence.files;
      };

  emptyPaths = {
    directories = [ ];
    files = [ ];
  };

  mergePaths = a: b: {
    directories = a.directories ++ b.directories;
    files = a.files ++ b.files;
  };

  filterMigratablePaths =
    paths:
    lib.filter (
      path:
      lib.hasPrefix "/" path
      && path != "/nix"
      && !lib.hasPrefix "/nix/" path
      && path != cfg.persistenceMountPoint
      && !lib.hasPrefix "${cfg.persistenceMountPoint}/" path
    ) paths;

  sortPathsParentFirst =
    paths:
    lib.sort (
      a: b:
      let
        lenA = builtins.stringLength a;
        lenB = builtins.stringLength b;
      in
      if lenA == lenB then a < b else lenA < lenB
    ) paths;

  normalizePaths = paths: {
    directories = sortPathsParentFirst (lib.unique (filterMigratablePaths paths.directories));
    files = lib.sort (a: b: a < b) (lib.unique (filterMigratablePaths paths.files));
  };

  persistencePaths = rec {
    system = mkPersistencePaths (config.environment.persistence.${cfg.persistenceMountPoint} or null);

    hm = lib.foldl' mergePaths emptyPaths (
      map (
        userConfig: mkPersistencePaths (userConfig.home.persistence.${cfg.persistenceMountPoint} or null)
      ) (lib.attrValues (config.home-manager.users or { }))
    );

    all = mergePaths system hm;
  };

  migrationPaths = normalizePaths persistencePaths.all;

  renderMigrationCalls =
    functionName: paths:
    lib.concatMapStrings (path: "      ${functionName} ${lib.escapeShellArg path}\n") paths;
in
{
  options.dotnix.impermanence = {
    enable = lib.mkEnableOption "host-side impermanence implementation (root reset + data migration).";

    persistenceMountPoint = lib.mkOption {
      type = lib.types.str;
      default = "/persist";
      description = "Mount point used by impermanence for persistent state.";
    };

    btrfsDevice = lib.mkOption {
      type = lib.types.str;
      default = rootFs.device;
      description = "Btrfs device that contains @root, @nix, and @persist subvolumes.";
    };

    btrfsMountOptions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "compress=zstd"
        "noatime"
      ];
      description = "Mount options for Btrfs subvolumes managed by dotnix impermanence.";
    };

    rootSnapshotRetention = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = "Number of archived @root snapshots to keep under @root-history.";
    };

    manageHomeDirTmpfiles = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to create normal users' home directories via systemd-tmpfiles.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = rootFs.fsType == "btrfs";
        message = "dotnix.impermanence requires fileSystems.\"/\".fsType = \"btrfs\"";
      }
      {
        assertion = config.system.activationScripts ? persist-files;
        message = "dotnix.impermanence requires impermanence file persistence activation support";
      }
      {
        assertion = lib.hasPrefix "/" cfg.persistenceMountPoint;
        message = "dotnix.impermanence.persistenceMountPoint must be an absolute path";
      }
      {
        assertion = cfg.persistenceMountPoint != "/";
        message = "dotnix.impermanence.persistenceMountPoint must not be \"/\"";
      }
    ];

    fileSystems."/" = {
      options = [ "subvol=@root" ] ++ cfg.btrfsMountOptions;
    };

    fileSystems."/nix" = {
      device = cfg.btrfsDevice;
      fsType = "btrfs";
      neededForBoot = true;
      options = [ "subvol=@nix" ] ++ cfg.btrfsMountOptions;
    };

    fileSystems.${cfg.persistenceMountPoint} = {
      device = cfg.btrfsDevice;
      fsType = "btrfs";
      neededForBoot = true;
      options = [ "subvol=@persist" ] ++ cfg.btrfsMountOptions;
    };

    systemd.tmpfiles.rules = lib.optionals cfg.manageHomeDirTmpfiles (
      lib.mapAttrsToList mkHomeDirTmpfilesRule managedHomeUsers
    );

    system.activationScripts.impermanence-persist-files-guard = {
      deps = [ "createPersistentStorageDirs" ];
      text = ''
        if ! findmnt ${lib.escapeShellArg cfg.persistenceMountPoint} >/dev/null 2>&1; then
          echo "[impermanence:activation] ${cfg.persistenceMountPoint} is not mounted yet." >&2
          echo "[impermanence:activation] Use boot-only deployment once (deploy --boot), then reboot." >&2
          exit 1
        fi
      '';
    };

    system.activationScripts.persist-files.deps = lib.mkAfter [ "impermanence-persist-files-guard" ];

    boot.initrd.postDeviceCommands = lib.mkAfter /* sh */ ''
      (
        set -e

        imperm_log() {
          echo "[impermanence:initrd] $*"
        }

        imperm_error() {
          echo "[impermanence:initrd] ERROR: $*" >&2
        }

        imperm_path_exists() {
          [ -e "$1" ] || [ -L "$1" ]
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

        imperm_is_subvolume() {
          btrfs subvolume show "$1" >/dev/null 2>&1
        }

        imperm_ensure_subvolume() {
          subvolume_name="$1"
          subvolume_path="/btrfs_tmp/$subvolume_name"

          if imperm_path_exists "$subvolume_path"; then
            if imperm_is_subvolume "$subvolume_path"; then
              return 0
            fi

            imperm_abort "Path $subvolume_path exists but is not a btrfs subvolume."
          fi

          imperm_log "Creating missing subvolume: $subvolume_name"
          btrfs subvolume create "$subvolume_path" || imperm_abort "Failed to create subvolume $subvolume_path."
        }

        imperm_directory_has_entries() {
          [ -d "$1" ] && [ -n "$(ls -A "$1" 2>/dev/null)" ]
        }

        imperm_move_directory_contents() {
          source_dir="$1"
          destination_dir="$2"

          for entry in "$source_dir"/* "$source_dir"/.[!.]* "$source_dir"/..?*; do
            if [ ! -e "$entry" ] && [ ! -L "$entry" ]; then
              continue
            fi

            mv "$entry" "$destination_dir"/ || imperm_abort "Failed to move $entry into $destination_dir."
          done
        }

        imperm_migrate_legacy_nix_store() {
          legacy_nix="/btrfs_tmp/nix"
          persisted_nix="/btrfs_tmp/@nix"

          imperm_ensure_subvolume "@nix"

          if [ -L "$legacy_nix" ]; then
            imperm_abort "Legacy /nix path is a symlink; refusing automatic migration."
          fi

          if [ ! -d "$legacy_nix" ]; then
            return 0
          fi

          if ! imperm_directory_has_entries "$legacy_nix"; then
            rmdir "$legacy_nix" >/dev/null 2>&1 || true
            return 0
          fi

          if imperm_directory_has_entries "$persisted_nix"; then
            imperm_log "Skipping legacy /nix migration because @nix already has content."
            return 0
          fi

          imperm_log "Migrating legacy /nix into @nix."
          imperm_move_directory_contents "$legacy_nix" "$persisted_nix"
          rmdir "$legacy_nix" >/dev/null 2>&1 || true
        }

        imperm_resolve_migration_source() {
          migration_path="$1"
          source_from_root="/btrfs_tmp/@root$migration_path"
          source_from_legacy="/btrfs_tmp$migration_path"

          if imperm_path_exists "$source_from_root"; then
            printf '%s\n' "$source_from_root"
            return 0
          fi

          if imperm_path_exists "$source_from_legacy"; then
            printf '%s\n' "$source_from_legacy"
            return 0
          fi

          return 1
        }

        imperm_source_root_for_path() {
          migration_path="$1"
          source_path="$2"

          if [ "$source_path" = "/btrfs_tmp/@root$migration_path" ]; then
            printf '%s\n' "/btrfs_tmp/@root"
            return 0
          fi

          if [ "$source_path" = "/btrfs_tmp$migration_path" ]; then
            printf '%s\n' "/btrfs_tmp"
            return 0
          fi

          imperm_abort "Unexpected migration source path for $migration_path: $source_path"
        }

        imperm_prepare_destination_parent() {
          migration_path="$1"
          source_path="$2"
          destination_parent="/btrfs_tmp/@persist$(dirname "$migration_path")"

          mkdir -p "$destination_parent" || imperm_abort "Failed to create destination parent for $migration_path"

          parent_path="$(dirname "$migration_path")"
          if [ "$parent_path" = "/" ]; then
            return 0
          fi

          source_root="$(imperm_source_root_for_path "$migration_path" "$source_path")"

          old_ifs="$IFS"
          IFS='/'

          current_path=""
          for segment in $parent_path; do
            [ -n "$segment" ] || continue

            current_path="$current_path/$segment"

            source_parent="$source_root$current_path"
            destination_parent="/btrfs_tmp/@persist$current_path"

            if [ -L "$source_parent" ] || [ ! -d "$source_parent" ]; then
              imperm_abort "Source parent for $migration_path is not a directory: $source_parent"
            fi

            if [ -L "$destination_parent" ] || [ ! -d "$destination_parent" ]; then
              imperm_abort "Persist parent for $migration_path is not a directory: $destination_parent"
            fi

            source_owner="$(stat -c '%u:%g' "$source_parent" 2>/dev/null)" || imperm_abort "Failed to read owner for $source_parent"
            source_mode="$(stat -c '%a' "$source_parent" 2>/dev/null)" || imperm_abort "Failed to read mode for $source_parent"

            chown "$source_owner" "$destination_parent" || imperm_abort "Failed to sync owner for $destination_parent"
            chmod "$source_mode" "$destination_parent" || imperm_abort "Failed to sync mode for $destination_parent"
          done

          IFS="$old_ifs"
        }

        imperm_migrate_directory() {
          migration_path="$1"
          destination="/btrfs_tmp/@persist$migration_path"

          if imperm_path_exists "$destination"; then
            if [ -L "$destination" ] || [ ! -d "$destination" ]; then
              imperm_abort "Persist destination exists but is not a directory: $destination"
            fi

            return 0
          fi

          if ! source_path="$(imperm_resolve_migration_source "$migration_path")"; then
            return 0
          fi

          if [ -L "$source_path" ] || [ ! -d "$source_path" ]; then
            imperm_abort "Source exists but is not a directory for $migration_path: $source_path"
          fi

          imperm_prepare_destination_parent "$migration_path" "$source_path"
          imperm_log "Migrating directory $migration_path to @persist."
          mv "$source_path" "$destination" || imperm_abort "Failed to migrate directory $migration_path."
        }

        imperm_migrate_file() {
          migration_path="$1"
          destination="/btrfs_tmp/@persist$migration_path"

          if imperm_path_exists "$destination"; then
            if [ -L "$destination" ]; then
              imperm_abort "Persist destination exists as a symlink (unsupported for migration): $destination"
            fi

            if [ -d "$destination" ] && [ ! -L "$destination" ]; then
              imperm_abort "Persist destination exists but is a directory: $destination"
            fi

            return 0
          fi

          if ! source_path="$(imperm_resolve_migration_source "$migration_path")"; then
            return 0
          fi

          if [ -L "$source_path" ]; then
            imperm_log "Skipping symlink source for $migration_path; file data is expected under @persist already."
            return 0
          fi

          if [ -d "$source_path" ] && [ ! -L "$source_path" ]; then
            imperm_abort "Source exists but is a directory for $migration_path: $source_path"
          fi

          if [ ! -f "$source_path" ]; then
            imperm_abort "Source exists but is not a regular file for $migration_path: $source_path"
          fi

          imperm_prepare_destination_parent "$migration_path" "$source_path"
          imperm_log "Migrating file $migration_path to @persist."
          mv "$source_path" "$destination" || imperm_abort "Failed to migrate file $migration_path."
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

        imperm_prune_old_root_snapshots() {
          snapshots="$(imperm_list_root_snapshots)"

          old_ifs="$IFS"
          IFS=$'\n'

          snapshot_count=0
          for snapshot in $snapshots; do
            [ -n "$snapshot" ] || continue
            snapshot_count=$((snapshot_count + 1))
          done

          remove_count=$((snapshot_count - ${toString cfg.rootSnapshotRetention}))
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
        mount -t btrfs -o subvolid=5 "${cfg.btrfsDevice}" /btrfs_tmp || imperm_abort "Failed to mount btrfs top-level."
        imperm_mounted=1
        imperm_log "Mounted btrfs top-level on /btrfs_tmp."

        imperm_ensure_subvolume "@persist"
        imperm_migrate_legacy_nix_store

        imperm_log "Migrating missing persistence paths into @persist."
        ${renderMigrationCalls "imperm_migrate_directory" migrationPaths.directories}${renderMigrationCalls "imperm_migrate_file" migrationPaths.files}

        if ! imperm_is_subvolume /btrfs_tmp/@nix || ! imperm_is_subvolume /btrfs_tmp/@persist; then
          imperm_abort "Expected @nix and @persist to be btrfs subvolumes after migration."
        fi
        imperm_log "Verified @nix and @persist subvolumes."

        if imperm_path_exists /btrfs_tmp/@root-blank && ! imperm_is_subvolume /btrfs_tmp/@root-blank; then
          imperm_abort "Path /btrfs_tmp/@root-blank exists but is not a subvolume."
        fi

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
        if imperm_path_exists /btrfs_tmp/@root && ! imperm_is_subvolume /btrfs_tmp/@root; then
          imperm_abort "Path /btrfs_tmp/@root exists but is not a subvolume."
        fi

        if imperm_is_subvolume /btrfs_tmp/@root; then
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
  };
}
