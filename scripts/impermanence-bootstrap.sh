#!/usr/bin/env bash

set -euo pipefail

DRY_RUN=1
DEVICE=""
MOUNT_POINT="/mnt"
HOME_USER="${SUDO_USER:-}"
MOUNTED=0

SYSTEM_PERSIST_DIRS=(
  "/var/log"
  "/var/lib/nixos"
  "/var/lib/systemd"
  "/var/lib/NetworkManager"
  "/var/lib/bluetooth"
  "/etc/NetworkManager/system-connections"
  "/etc/ssh"
  "/var/lib/sops-nix"
  "/root"
)

HOME_PERSIST_DIRS=(
  "Desktop"
  "Documents"
  "Downloads"
  "Music"
  "Pictures"
  "Public"
  "Templates"
  "Videos"
  ".sops-nix"
  ".ssh"
  ".gnupg"
)

usage() {
  cat <<'EOF'
Usage: impermanence-bootstrap.sh [options]

Bootstrap btrfs impermanence subvolumes for this repository.

Options:
  --apply                 Apply changes (default is dry-run)
  --device <path>         Btrfs root block device/source (auto-detected from /)
  --mount-point <path>    Temporary mount point for top-level subvolume (default: /mnt)
  --home-user <name>      Optional home user to migrate into /persist/home/<name>
  -h, --help              Show this help

Examples:
  sudo ./scripts/impermanence-bootstrap.sh
  sudo ./scripts/impermanence-bootstrap.sh --apply
  sudo ./scripts/impermanence-bootstrap.sh --apply --home-user cheng
EOF
}

log() {
  printf '[impermanence-bootstrap] %s\n' "$*"
}

die() {
  printf '[impermanence-bootstrap] ERROR: %s\n' "$*" >&2
  exit 1
}

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

quote_cmd() {
  local rendered
  rendered="$(printf '%q ' "$@")"
  printf '%s' "${rendered% }"
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] $(quote_cmd "$@")"
    return 0
  fi

  log "+ $(quote_cmd "$@")"
  "$@"
}

cleanup() {
  if [[ "$MOUNTED" -eq 1 ]]; then
    umount "$MOUNT_POINT" >/dev/null 2>&1 || true
    MOUNTED=0
  fi
}

subvolume_exists() {
  local name="$1"
  [[ -d "$MOUNT_POINT/$name" ]]
}

dir_has_content() {
  local path="$1"
  [[ -d "$path" ]] && [[ -n "$(ls -A "$path" 2>/dev/null || true)" ]]
}

ensure_subvolume() {
  local name="$1"
  local path="$MOUNT_POINT/$name"

  if subvolume_exists "$name"; then
    log "Keep existing subvolume: $name"
    return 0
  fi

  run btrfs subvolume create "$path"
}

sync_directory() {
  local source_dir="$1"
  local destination_dir="$2"

  if [[ ! -d "$source_dir" ]]; then
    log "Skip missing directory: $source_dir"
    return 0
  fi

  run mkdir -p "$destination_dir"
  run rsync -aHAX --numeric-ids "$source_dir/" "$destination_dir/"
}

sync_file() {
  local source_file="$1"
  local destination_file="$2"

  if [[ ! -f "$source_file" ]]; then
    log "Skip missing file: $source_file"
    return 0
  fi

  run mkdir -p "$(dirname "$destination_file")"
  run rsync -aHAX --numeric-ids "$source_file" "$destination_file"
}

migrate_system_persistence() {
  log "Preparing system persistence data under @persist"

  local src
  for src in "${SYSTEM_PERSIST_DIRS[@]}"; do
    sync_directory "$src" "$MOUNT_POINT/@persist$src"
  done

  sync_file "/etc/machine-id" "$MOUNT_POINT/@persist/etc/machine-id"
}

migrate_home_persistence() {
  local user_name="$1"

  if [[ -z "$user_name" ]]; then
    log "Skip home migration: no --home-user provided"
    return 0
  fi

  local home_dir
  home_dir="$(getent passwd "$user_name" | cut -d: -f6)"
  if [[ -z "$home_dir" ]]; then
    die "Cannot resolve home directory for user '$user_name'"
  fi

  local persist_home_root="$MOUNT_POINT/@persist/home/$user_name"
  run mkdir -p "$persist_home_root"

  log "Preparing home persistence data for user: $user_name"

  local rel
  for rel in "${HOME_PERSIST_DIRS[@]}"; do
    sync_directory "$home_dir/$rel" "$persist_home_root/$rel"
  done

  sync_file "$home_dir/.local/share/fish/fish_history" "$persist_home_root/.local/share/fish/fish_history"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --apply)
        DRY_RUN=0
        shift
        ;;
      --device)
        [[ $# -ge 2 ]] || die "--device requires a value"
        DEVICE="$2"
        shift 2
        ;;
      --mount-point)
        [[ $# -ge 2 ]] || die "--mount-point requires a value"
        MOUNT_POINT="$2"
        shift 2
        ;;
      --home-user)
        [[ $# -ge 2 ]] || die "--home-user requires a value"
        HOME_USER="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  [[ "$EUID" -eq 0 ]] || die "Run this script as root (use sudo)."

  has_cmd btrfs || die "Missing command: btrfs"
  has_cmd findmnt || die "Missing command: findmnt"
  has_cmd mount || die "Missing command: mount"
  has_cmd umount || die "Missing command: umount"
  has_cmd rsync || die "Missing command: rsync"
  has_cmd getent || die "Missing command: getent"

  if [[ -z "$DEVICE" ]]; then
    DEVICE="$(findmnt -n -o SOURCE / || true)"
  fi
  [[ -n "$DEVICE" ]] || die "Failed to auto-detect root source. Use --device."

  local root_fs_type
  root_fs_type="$(findmnt -n -o FSTYPE / || true)"
  [[ "$root_fs_type" == "btrfs" ]] || die "Root filesystem is '$root_fs_type', expected btrfs."

  trap cleanup EXIT

  mkdir -p "$MOUNT_POINT"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Running in dry-run mode (read-only mount, no writes)."
    mount -t btrfs -o subvolid=5,ro "$DEVICE" "$MOUNT_POINT"
  else
    log "Applying changes (read-write mount)."
    mount -t btrfs -o subvolid=5 "$DEVICE" "$MOUNT_POINT"
  fi
  MOUNTED=1

  ensure_subvolume "@root"

  # Keep a minimal baseline root layout compatible with the initrd reset logic.
  run mkdir -p "$MOUNT_POINT/@root/boot"
  run mkdir -p "$MOUNT_POINT/@root/etc"
  run mkdir -p "$MOUNT_POINT/@root/home"
  run mkdir -p "$MOUNT_POINT/@root/nix"
  run mkdir -p "$MOUNT_POINT/@root/persist"
  run mkdir -p "$MOUNT_POINT/@root/root"
  run mkdir -p "$MOUNT_POINT/@root/tmp"
  run mkdir -p "$MOUNT_POINT/@root/var"
  run chmod 1777 "$MOUNT_POINT/@root/tmp"

  if subvolume_exists "@root-blank"; then
    log "Keep existing subvolume: @root-blank"
  else
    run btrfs subvolume snapshot "$MOUNT_POINT/@root" "$MOUNT_POINT/@root-blank"
    run btrfs property set -ts "$MOUNT_POINT/@root-blank" ro true
  fi

  ensure_subvolume "@nix"
  ensure_subvolume "@persist"

  if dir_has_content "$MOUNT_POINT/@nix"; then
    log "Skip /nix migration: @nix already has content"
  else
    sync_directory "/nix" "$MOUNT_POINT/@nix"
  fi

  migrate_system_persistence
  migrate_home_persistence "$HOME_USER"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "Dry-run finished. Re-run with --apply to execute changes."
  else
    log "Bootstrap finished. Next step: rebuild, then reboot and validate mounts."
  fi
}

main "$@"
