#!/usr/bin/env bash
# Installer-side helper for docs/new-machine.md. Two-phase on purpose:
#
#   phase 1  only WRITES files (hardware config, host scaffold, flake
#            registration) and exits so everything can be reviewed;
#   phase 2  evaluates the flake and runs the actual install.
#
# Run ON the NixOS installer, as root, with the target mounted at /mnt:
#
#   bash scripts/bootstrap-installer.sh <host>          # phase 1
#   bash scripts/bootstrap-installer.sh <host> --yes    # phase 2
#
# Not for reruns on an existing installation: this only drives a fresh
# nixos-install against a mounted /mnt.
set -euo pipefail

usage() {
  echo "usage: $0 <host> [--yes]" >&2
  echo "  <host>  new host name, e.g. tkpd" >&2
  exit 2
}

[[ ${1:-} != "" ]] || usage
HOST="$1"
shift || true
ASSUME_YES="no"
if [[ ${1:-} == "--yes" ]]; then
  ASSUME_YES="yes"
  shift || true
fi
[[ $# -eq 0 ]] || usage

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST_DIR="$REPO/hosts/$HOST"
HW_SRC="/mnt/etc/nixos/hardware-configuration.nix"
HW_DEST="$HOST_DIR/hardware-configuration.nix"
export NIX_CONFIG="${NIX_CONFIG:-experimental-features = nix-command flakes}"

die() {
  echo "error: $*" >&2
  exit 1
}

mountpoint -q /mnt ||
  die "/mnt is not mounted; finish the partitioning step of docs/new-machine.md first."

phase_write_files() {
  [[ -f $HW_SRC ]] ||
    die "$HW_SRC is missing; run 'nixos-generate-config --root /mnt' and review it first."

  if [[ ! -f $HW_DEST ]] || grep -q "not real yet" "$HW_DEST"; then
    cp -v "$HW_SRC" "$HW_DEST"
  else
    echo "ok: $HW_DEST already exists and is not a placeholder."
  fi

  [[ -d $HOST_DIR ]] || mkdir -p "$HOST_DIR"

  if [[ ! -s $HOST_DIR/authorized_keys ]]; then
    curl -fsSL https://github.com/osdva.keys -o "$HOST_DIR/authorized_keys" ||
      die "could not fetch https://github.com/osdva.keys; write authorized_keys by hand."
  fi

  if [[ ! -f $HOST_DIR/default.nix ]]; then
    cat > "$HOST_DIR/default.nix" <<EOF
{ user, ... }:
{
  imports = [ ./hardware-configuration.nix ];

  # Encrypted install (docs/new-machine.md Option A): adjust the device and uncomment.
  # boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/<uuid>";
  # Laptop role: point at the swap partition for hibernation.
  # boot.resumeDevice = "/dev/disk/by-uuid/<swap-uuid>";

  users.users.\${user}.openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];

  # TODO: set to the release being installed, then never bump it.
  system.stateVersion = "$(nixos-version | cut -d. -f1-2)";
}
EOF
    echo "wrote $HOST_DIR/default.nix"
  else
    echo "ok: $HOST_DIR/default.nix already exists."
  fi

  if ! grep -q "^        $HOST = lib.mkHost" "$REPO/flake.nix"; then
    # Default roles; edit flake.nix afterwards (e.g. add "laptop", or use "server").
    sed -i "/nixosConfigurations = {/a\\        $HOST = lib.mkHost { hostname = \"$HOST\"; roles = [ \"workstation\" \"development\" ]; };" "$REPO/flake.nix"
    echo "registered $HOST in flake.nix"
  else
    echo "ok: $HOST already registered in flake.nix."
  fi

  echo
  echo "Phase 1 done. REVIEW before installing:"
  echo "  git -C $REPO status"
  echo "  git -C $REPO diff"
  echo "  \$EDITOR $HOST_DIR/default.nix"
  echo "  \$EDITOR $HOST_DIR/hardware-configuration.nix"
  echo
  echo "Then run phase 2:"
  echo "  $0 $HOST --yes"
}

phase_install() {
  if [[ $ASSUME_YES != "yes" ]]; then
    read -r -p "Install NixOS for host '$HOST' on the disks mounted at /mnt? [y/N] " answer
    [[ $answer == y ]] || die "aborted by user"
  fi

  echo "evaluating $HOST without building..."
  nix flake check "path:$REPO" --no-build

  echo "installing (this builds the system; not interactive)..."
  nixos-install --flake "path:$REPO#$HOST"

  echo
  echo "Set the user's password in the installed system:"
  nixos-enter --root /mnt --run 'passwd osdva'

  echo
  echo "Done. Reboot, log in as osdva, clone this repo to ~/dev/nix, and run:"
  echo "  sudo nixos-rebuild switch --flake ~/dev/nix#$HOST"
}

if [[ $ASSUME_YES == "yes" ]]; then
  phase_install
else
  phase_write_files
  exit 0
fi
