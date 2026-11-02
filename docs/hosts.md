# Adding a host

Every machine is one line in `flake.nix` plus a directory in `hosts/`:

```nix
# flake.nix → nixosConfigurations
desktop = lib.mkHost { hostname = "desktop"; roles = [ "workstation" "development" ]; };
homelab = lib.mkHost { hostname = "homelab"; roles = [ "server" ]; };
pi      = lib.mkHost { hostname = "pi"; system = "aarch64-linux"; roles = [ "server" ]; };
```

`roles` are files in `modules/nixos/roles/`. Mix them freely:

| role          | gives you                                                         |
| ------------- | ----------------------------------------------------------------- |
| `workstation` | mango + Noctalia, ly login, audio, fonts, apps, Bitwarden SSH agent |
| `laptop`      | hibernate policy, thermald (needs `boot.resumeDevice`)            |
| `development` | Podman, nix-ld, language toolchains, nvim config                  |
| `server`      | headless, networkd, passwordless sudo for remote deploys          |

Every host also gets `modules/nixos/core` (nix settings, locale, user, key-only
sshd, fish) and the Home Manager base in `home/default.nix` (fish, git, tmux,
CLI tools).

## Host directory

```text
hosts/<name>/
  default.nix                  imports hardware file, host quirks, stateVersion
  hardware-configuration.nix   from `nixos-generate-config` on that machine
```

SSH access comes from `keys/osdva.pub`, which core authorizes on every host.
A host that should accept extra keys adds them with
`users.users.${user}.openssh.authorizedKeys.keys`.

Minimal `default.nix`:

```nix
{ ... }:
{
  imports = [ ./hardware-configuration.nix ];
  system.stateVersion = "26.05"; # the release you installed; never bump it
}
```

Examples of host-only things: `boot.resumeDevice`, nixos-hardware modules,
monitor layout, GPU drivers, homelab services (`services.jellyfin.enable`, …),
`networking.interfaces`, a static IP, extra firewall ports.

Homelab services that several servers share should become their own module
under `modules/nixos/services/` and be imported from the host.

## Existing NixOS machine

```sh
git clone git@github.com:osdva/nix.git ~/dev/nix && cd ~/dev/nix
mkdir hosts/<name>
cp /etc/nixos/hardware-configuration.nix hosts/<name>/
$EDITOR hosts/<name>/default.nix flake.nix
git add -A    # flakes only see files git knows about
sudo nixos-rebuild switch --flake .#<name>
```

Use the `system.stateVersion` from that machine's current
`/etc/nixos/configuration.nix`.

## Fresh install

See [new-machine.md](new-machine.md).

## Homelab: deploy from the laptop

The `server` role allows passwordless sudo for wheel, so you can deploy over SSH
(your Bitwarden key needs to be in `keys/osdva.pub`):

```sh
nixos-rebuild switch --flake ~/dev/nix#homelab --target-host homelab --sudo
# build on the server instead of locally:
nixos-rebuild switch --flake ~/dev/nix#homelab --target-host homelab --build-host homelab --sudo
```

To build an aarch64 host (Pi) on the laptop, add
`boot.binfmt.emulatedSystems = [ "aarch64-linux" ];` to `hosts/tkpd`.
