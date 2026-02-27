{ config, lib, ... }:

let
  rootFs = config.fileSystems."/";
  btrfsDevice = rootFs.device;
  persistenceMountPoint = "/persist";
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

  systemPersistence = config.environment.persistence.${persistenceMountPoint} or null;

  systemPersistenceDirectories =
    if systemPersistence == null || !(systemPersistence.enable or true) then
      [ ]
    else
      map (entry: toString entry.dirPath) systemPersistence.directories;

  systemPersistenceFiles =
    if systemPersistence == null || !(systemPersistence.enable or true) then
      [ ]
    else
      map (entry: toString entry.filePath) systemPersistence.files;

  homeManagerPersistenceDirectories = lib.concatMap (
    userConfig:
    let
      homePersistence = userConfig.home.persistence.${persistenceMountPoint} or null;
    in
    if homePersistence == null || !(homePersistence.enable or true) then
      [ ]
    else
      map (entry: toString entry.dirPath) homePersistence.directories
  ) (lib.attrValues (config.home-manager.users or { }));

  homeManagerPersistenceFiles = lib.concatMap (
    userConfig:
    let
      homePersistence = userConfig.home.persistence.${persistenceMountPoint} or null;
    in
    if homePersistence == null || !(homePersistence.enable or true) then
      [ ]
    else
      map (entry: toString entry.filePath) homePersistence.files
  ) (lib.attrValues (config.home-manager.users or { }));

  filterMigratablePaths =
    paths:
    lib.filter (
      path:
      lib.hasPrefix "/" path
      && path != "/nix"
      && !lib.hasPrefix "/nix/" path
      && path != persistenceMountPoint
      && !lib.hasPrefix "${persistenceMountPoint}/" path
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

  migrationDirectoryPaths = sortPathsParentFirst (
    lib.unique (
      filterMigratablePaths (systemPersistenceDirectories ++ homeManagerPersistenceDirectories)
    )
  );

  migrationFilePaths = lib.sort (a: b: a < b) (
    lib.unique (filterMigratablePaths (systemPersistenceFiles ++ homeManagerPersistenceFiles))
  );

  renderMigrationCalls =
    functionName: paths:
    lib.concatMapStrings (path: "      ${functionName} ${lib.escapeShellArg path}\n") paths;
in
{
  assertions = [
    {
      assertion = rootFs.fsType == "btrfs";
      message = "mochi impermanence requires fileSystems.\"/\".fsType = \"btrfs\"";
    }
    {
      assertion = config.system.activationScripts ? persist-files;
      message = "mochi impermanence requires impermanence file persistence activation support";
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

  system.activationScripts.impermanence-persist-files-guard = {
    deps = [ "createPersistentStorageDirs" ];
    text = ''
      if ! findmnt /persist >/dev/null 2>&1; then
        echo "[impermanence:activation] /persist is not mounted yet." >&2
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

        mkdir -p "$(dirname "$destination")"
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

        mkdir -p "$(dirname "$destination")"
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

      imperm_ensure_subvolume "@persist"
      imperm_migrate_legacy_nix_store

      imperm_log "Migrating missing persistence paths into @persist."
      ${renderMigrationCalls "imperm_migrate_directory" migrationDirectoryPaths}${renderMigrationCalls "imperm_migrate_file" migrationFilePaths}

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
}
