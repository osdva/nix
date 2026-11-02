# Not set up yet (options considered on 2026-11-01)

These were left out of the first setup. Each can be added without
restructuring the repo.

## sops-nix: secrets in the repo, encrypted

**What:** encrypt secrets (API keys, wifi passwords, `CONTEXT7_API_KEY`, homelab
service credentials, user password hashes) with age and commit them. They are
decrypted at activation into `/run/secrets`, never into the Nix store.

**Why it would help:** rbw covers interactive use, but system services (homelab
credentials, wifi, password hashes) need secrets at boot without a vault unlock.

**How:**

```nix
# flake.nix inputs
sops-nix = { url = "github:Mic92/sops-nix"; inputs.nixpkgs.follows = "nixpkgs"; };
# lib/default.nix modules
inputs.sops-nix.nixosModules.sops
```

```sh
# each host's age key comes from its SSH host key
nix shell nixpkgs#ssh-to-age -c sh -c 'ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub'
# list the host keys + your personal age key in .sops.yaml, then:
nix shell nixpkgs#sops -c sops secrets/tkpd.yaml
```

```nix
sops.defaultSopsFile = ../../secrets/${hostname}.yaml;
sops.secrets.context7_api_key.owner = user;
# fish: set -x CONTEXT7_API_KEY (cat /run/secrets/context7_api_key)
```

Alternative: **agenix** (simpler, one file per secret, no YAML).

## disko: declarative partitioning

**What:** the partition layout (ESP, LUKS, btrfs subvolumes, swap) written in
Nix. `nixos-anywhere` or `disko --mode disko` creates it on a new disk.

**Why it would help:** new installs, especially homelab boxes, become
`nixos-anywhere --flake .#homelab root@<ip>` with no manual partitioning
(docs/new-machine.md step 5).

**Caveat:** it does not repartition existing machines. For tkpd it would only
describe what is already there (ext4 + 68 GB swap), so start with new hosts.

```nix
disko = { url = "github:nix-community/disko"; inputs.nixpkgs.follows = "nixpkgs"; };
# hosts/<name>/disko.nix → disko.devices.disk.main = { device = "/dev/nvme0n1"; content = { type = "gpt"; partitions = { … }; }; };
```

A swap partition at least the size of RAM keeps hibernation working
(`boot.resumeDevice = "/dev/disk/by-partlabel/disk-main-swap"`).

## nix-index + comma

**What:** a prebuilt index of every file in nixpkgs.
- `, cowsay hi` runs any program without installing it.
- "command not found" suggests which package provides it.
- `nix-locate bin/rg` searches the index.

**How:** one input and three lines, no database to build yourself:

```nix
nix-index-database = { url = "github:nix-community/nix-index-database"; inputs.nixpkgs.follows = "nixpkgs"; };
# home/default.nix
imports = [ inputs.nix-index-database.homeModules.nix-index ];
programs.nix-index.enable = true;
programs.nix-index-database.comma.enable = true;
```

## Other ideas

- **impermanence:** wipe `/` on every boot and persist only declared paths. It
  forces everything to be declarative. Needs btrfs or tmpfs root, so it is a
  reinstall.
- **lanzaboote:** Secure Boot with systemd-boot. Note that hibernation stays
  possible only without kernel lockdown.
- **nix-flatpak:** declare Flatpak apps.
- **Helium browser:** not in nixpkgs; package it or use the AppImage.
- **deploy-rs / colmena:** multi-host deploys once the homelab has several
  machines (`nixos-rebuild --target-host` is enough for 1–2).
- **Hydra/attic/cachix:** a binary cache so the homelab doesn't rebuild what the
  laptop already built.
