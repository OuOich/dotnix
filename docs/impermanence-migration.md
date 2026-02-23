# Impermanence Migration Runbook (mochi)

This runbook covers the one-time migration to the current impermanence layout:

- `@root` (ephemeral system root)
- `@root-blank` (read-only baseline)
- `@nix` (`/nix`)
- `@persist` (`/persist`)

It also covers first-boot validation and recovery.

## 1. Pre-flight checks

1. Build current config and keep at least one known-good generation:

   ```bash
   nix flake check
   nix build .#nixosConfigurations.mochi.config.system.build.toplevel
   ```

1. Make sure root filesystem is btrfs:

   ```bash
   findmnt -no FSTYPE /
   ```

1. Ensure backups are available before touching subvolumes.

## 2. Bootstrap subvolumes (with dry-run first)

Use the bootstrap helper from repository root:

```bash
sudo ./scripts/impermanence-bootstrap.sh
```

Dry-run mode mounts top-level btrfs read-only and prints the planned changes.

If output looks correct, apply:

```bash
sudo ./scripts/impermanence-bootstrap.sh --apply
```

The script handles:

- creating missing `@root`, `@root-blank`, `@nix`, `@persist`
- initializing the `@root` baseline directories
- syncing current `/nix` into `@nix` when needed
- syncing system persistence paths into `@persist`

Optional home migration for current user data:

```bash
sudo ./scripts/impermanence-bootstrap.sh --apply --home-user cheng
```

## 3. First reboot checklist

After `nixos-rebuild switch --flake .#mochi` and reboot, verify:

1. mount layout:

   ```bash
   findmnt /
   findmnt /nix
   findmnt /persist
   ```

1. root subvolume:

   ```bash
   findmnt -no OPTIONS /
   ```

   Expect `subvol=@root` in options.

1. `machine-id` is stable across reboot:

   ```bash
   cat /etc/machine-id
   ```

1. expected persistence exists:

   ```bash
   ls -la /persist
   ls -la /persist/home/cheng
   ```

## 4. Recovery from failed boot

If initrd fails due to wrong subvolume layout:

1. Boot a live environment and mount top-level btrfs:

   ```bash
   mount -t btrfs -o subvolid=5 /dev/disk/by-uuid/ <ROOT-UUID >/mnt
   btrfs subvolume list /mnt
   ```

1. Ensure required subvolumes exist: `@nix`, `@persist`, `@root-blank`.

1. Restore `@root` from the latest archived root (if needed):

   ```bash
   latest="$(ls -1 /mnt/@root-history | sort | tail -n 1)"
   btrfs subvolume snapshot "/mnt/@root-history/${latest}" /mnt/@root
   ```

1. Unmount and reboot:

   ```bash
   umount /mnt
   reboot
   ```

## 5. Notes

- Current initrd policy keeps latest 3 archived `@root` snapshots under `@root-history`.
- System persistence now includes `/etc/machine-id`.
- Home persistence root is `/persist/home/<username>`.
