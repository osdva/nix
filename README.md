#### osdva nix

> machine:
> thinkpad t14 gen 5 - intel ultra 5 135u - 64gb ddr5

nixos + home manager flake for all my machines. niri, noctalia, bitwarden, nvim.

if you want to see what gets installed go to `./modules/nixos/roles/` and `./home/`

wanna try?

```bash
# fresh install, from the nixos installer (disk partitioned and mounted at /mnt)
git clone https://github.com/osdva/nix.git /tmp/nix && bash /tmp/nix/scripts/bootstrap-installer.sh <host>

# review the generated files, then install
bash /tmp/nix/scripts/bootstrap-installer.sh <host> --yes

# existing nixos
git clone git@github.com:osdva/nix.git ~/dev/nix && sudo nixos-rebuild switch --flake ~/dev/nix#<host>
```

new machine: `docs/new-machine.md` · new host: `docs/hosts.md`
