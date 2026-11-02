# Installing NixOS on a new physical machine

Step-by-step guide for setting up a host of this flake on real hardware. The
repetitive installer-side steps are wrapped in
[`scripts/bootstrap-installer.sh`](../scripts/bootstrap-installer.sh); here the
same steps are shown manually so you always know what runs on your disks.

> **Before you start**
>
> - This guide assumes one target machine ("the target") and an existing
>   machine or phone to read docs if you SSH into the installer.
> - **Everything on the target's disks gets destroyed.** Back up first, and
>   read every command before pressing Enter.
> - The repo (`github.com/osdva/nix`) is **private**: plain `git clone` needs an
>   SSH key with repo access; the `curl` paths below use a GitHub token.
> - Never install against a guessed hardware configuration — the flake
>   deliberately fails to evaluate until a real
>   `hardware-configuration.nix` is in place.

## 1. Download and verify the installer ISO

From any machine:

```sh
# Latest nixos-26.05 minimal ISO (check channels.nixos.org for the current
# stable release name; adjust the channel and file naming accordingly)
curl -fLO https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso
curl -fLO https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso.sha256

sha256sum --check latest-nixos-minimal-x86_64-linux.iso.sha256
```

!!! verify "Before writing to disk"
    `sha256sum --check` must print `latest-nixos-minimal-x86_64-linux.iso: OK`.
    If it reports a mismatch, delete the file and re-download.

## 2. Write it to a USB stick

```sh
# Identify the USB device (not a partition): use the whole disk node.
lsblk -o NAME,SIZE,MODEL,TRAN

# WARNING: this overwrites the device below. Double-check the node.
sudo dd if=latest-nixos-minimal-x86_64-linux.iso \
        of=/dev/sdX bs=4M status=progress oflag=direct conv=fsync
```

## 3. Boot the installer on the target

1. Enter firmware setup (ThinkPad: F1 during boot) and check:
   - Boot mode: **UEFI** only.
   - Security → Secure Boot: **temporarily disabled**.
   - Enable the machine's VT-x/Intel Virtualization Technology if you ever want
     nested virtualization or Podman VMs.
2. Boot from the USB stick and pick the default NixOS installer entry.
3. Connect to the network (use the installer's NetworkManager applet or
   `nmcli`; below is the CLI form):

```sh
nmcli device wifi list
nmcli device wifi connect "YourSSID" password "yourpassword"
ping -c1 github.com
```

## 4. (Recommended) SSH into the installer

Typing long commands on a console is error-prone. Set a temporary root
password and fetch your GitHub public keys with `curl`:

```sh
passwd root
curl -fsSL https://github.com/osdva.keys > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys

# On your other machine (its key must be in your GitHub account):
ssh root@<installer-ip>
```

Log in from there and continue; everything below runs as root unless noted.

## 5. Partition the disk

Two supported layouts. For either, first identify the target disk:

```sh
lsblk -o NAME,SIZE,MODEL,TRAN
# e.g. /dev/nvme0n1 — replace every /dev/ path below with yours
```

### Option A — full-disk LUKS + btrfs (recommended)

```sh
DISK=/dev/nvme0n1
LUKS_NAME=cryptroot

# Wipe the partition table, then create an ESP and the LUKS container.
wipefs -af "$DISK"
sgdisk -Z "$DISK" \
  -n 1:0:+1GiB   -t 1:ef00 \
  -n 2:0:-16GiB  -t 2:8309 \
  -n 3:0:0       -t 3:8200   # swap partition at the end (remove if unwanted)

# Encrypt, format, and open (sets a disk passphrase — keep it safe!)
cryptsetup luksFormat --type luks2 --batch-mode "${DISK}-part2"
cryptsetup open "${DISK}-part2" "$LUKS_NAME"

mkfs.fat -F32 -n ESP "${DISK}-part1"
mkswap -L swap "${DISK}-part3"
mkfs.btrfs -L nixos /dev/mapper/"$LUKS_NAME"

# Btrfs subvolumes: /root for everything, a separate /home
mount /dev/mapper/"$LUKS_NAME" /mnt
btrfs subvolume create /mnt/root
btrfs subvolume create /mnt/home
umount /mnt

# Mount with sane Btrfs/SSD options
mount -o subvol=root,compress=zstd,noatime /dev/mapper/"$LUKS_NAME" /mnt
mount --mkdir -o subvol=home,compress=zstd,noatime /dev/mapper/"$LUKS_NAME" /mnt/home
mount --mkdir -o fmask=0077,dmask=0077 "${DISK}-part1" /mnt/boot
swapon "${DISK}-part3"
```

### Option B — plain EFI + ext4 (no encryption)

```sh
DISK=/dev/nvme0n1

wipefs -af "$DISK"
sgdisk -Z "$DISK" \
  -n 1:0:+1GiB -t 1:ef00 \
  -n 2:0:0     -t 2:8309

mkfs.fat -F32 -n ESP "${DISK}-part1"
mkfs.ext4 -L nixos "${DISK}-part2"

mount "${DISK}-part2" /mnt
mount --mkdir -o fmask=0077,dmask=0077 "${DISK}-part1" /mnt/boot
```

Whichever option you pick: `mountpoint /mnt` must succeed before continuing.

## 6. Generate and review the hardware configuration

```sh
nixos-generate-config --root /mnt

# REVIEW — this is the only file that knows the real disks:
$EDITOR /mnt/etc/nixos/hardware-configuration.nix
```

Checklist while reviewing:

- All expected filesystems and swap are listed, `device` paths match step 5.
- For Option A, the LUKS entry is correct and swap is listed as
  `"${DISK}-part3"` (add
  `boot.initrd.luks.devices."<name>".device` fixes by hand if needed).
- `nix.settings.max-jobs` and other Nix knobs stay in the flake, not here.
- The generated `/mnt/etc/nixos/configuration.nix` is **not used** by this
  repo — the flake replaces it. Leave it or delete it; just don't edit it.

## 7. Get this repo onto the installer

From the root shell on the target:

### Option A — SSH clone (needs a key with repo access)

```sh
# Least typing: paste/add an existing key you carry, or generate one here and
# add it to GitHub from another browser.
git clone git@github.com:osdva/nix.git /tmp/nix
```

### Option B — curl a tarball with a GitHub token

Get a token worth of access from any machine with `gh` (`gh auth token`),
then:

```sh
export GH_TOKEN=<paste-token-here>

curl -fL -H "Authorization: Bearer $GH_TOKEN" \
     https://api.github.com/repos/osdva/nix/tarball/main \
     | tar xz -C /tmp
mv /tmp/osdva-nix-* /tmp/nix
```

## 8. Create the host (or run the bootstrap script)

The fastest path is the bootstrap script; it copies the reviewed hardware
file, scaffolds a host, registers it in the flake, and runs the checks. It is
**two-phase on purpose**: phase one only writes files and exits so you can
review them.

```sh
bash /tmp/nix/scripts/bootstrap-installer.sh <name>
```

To do it by hand instead:

```sh
HOST=<name>   # e.g. tkpd, second-machine

# 1. Host directory + hardware file from step 6
mkdir -p /tmp/nix/hosts/$HOST
cp /mnt/etc/nixos/hardware-configuration.nix /tmp/nix/hosts/$HOST/

# 2. Authorized keys (public data, safe to commit)
curl -fsSL https://github.com/osdva.keys > /tmp/nix/hosts/$HOST/authorized_keys

# 3. Host module — copy hosts/tkpd/default.nix as a template and adjust.
#    MUST fill in per host: hostname, bootloader/encryption (for Option A add
#    boot.initrd.luks), hardware file import, real authentication.
$EDITOR /tmp/nix/hosts/$HOST/default.nix

# 4. Register it in flake.nix (inside nixosConfigurations = { ... }):
#      $HOST = lib.mkHost { hostname = "$HOST"; roles = [ "workstation" "development" ]; };
sed -i "/nixosConfigurations = {/a\\        $HOST = lib.mkHost { hostname = \"$HOST\"; roles = [ \"workstation\" \"development\" ]; };" \
  /tmp/nix/flake.nix

git -C /tmp/nix diff --stat   # review everything the script/editor changed
```

!!! note
    `system.stateVersion` in `hosts/<name>/default.nix` must match the
    NixOS release you are installing (release "26.05" for the 26.05 ISO in
    this guide). Once you first boot, never bump it.

## 9. Evaluate without installing

The installer's Nix needs flakes enabled (the minimal ISO does not export the
option by default). Always prefix `NIX_CONFIG` as shown:

```sh
export NIX_CONFIG="experimental-features = nix-command flakes"
nix flake check "path:/tmp/nix" --no-build
```

If this fails to evaluate, fix the errors before touching the target disk
(usually a typo in the host file or the hardware file wasn't reviewed).

## 10. Install

```sh
nixos-install --flake "path:/tmp/nix#<name>"
```

The prompt at the end sets the **root** password. Your normal user's password
still needs defining (see step 4 of the host-creation template):

```sh
sudo nixos-enter --root /mnt --run 'passwd <user>'
```

When both are set:

```sh
reboot
```

> Remove the USB stick when the firmware reboots. Re-enable Secure Boot later
> only after testing that the machine boots fine without it.

## 11. First boot

1. Log in at console/greeter as your user, with the password from step 10.
2. Re-clone the repo to its normal home and adopt a first `git` commit for the
   new host so the working tree stays clean:

```sh
git clone git@github.com:osdva/nix.git ~/dev/nix
cd ~/dev/nix
git status            # files may differ slightly from what you hand-edited
git add hosts/<name> && git commit -m "Add host <name>"
```

3. Rebuild from the adopted tree and run the post-install steps:

```sh
sudo nixos-rebuild switch --flake "path:$PWD#<name>"
```

4. Set up the Bitwarden SSH agent (docs/next-steps.md step 3), then migrate the
   personal bits (accounts/vaults, VPN, printing, fingerprint enrollment).

## Troubleshooting

- **`error: experimental Nix feature 'nix-command flakes' is disabled`** —
  you forgot `NIX_CONFIG="experimental-features = nix-command flakes"`.
- **`error: ... 'nixosConfigurations.<name>' attribute not found`** — the host
  wasn't registered in `flake.nix`; check step 8.4.
- **Wi-Fi dead after switching to the installed system** — NetworkManager is
  enabled by the shared base module; check `nmcli device` for a firmware
  issue or `rfkill list`.
- **Boot loop / firmware won't boot the ESP** — confirm the EFI system
  partition mounted at `/mnt/boot` is the one you formatted (FAT32, ~1 GiB)
  and `boot.loader.efi.canTouchEfiVariables = true` in the host file.
