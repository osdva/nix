# Next steps after the migration (tkpd)

Run these in order after the switch from `/etc/nixos` to this flake.

## 1. Switch to the flake (from the current Plasma system)

```sh
cd ~/dev/nix
git add -A                                    # flakes only see tracked files
nix flake check --no-build                    # optional: evaluate every host
sudo nixos-rebuild boot --flake ~/dev/nix#tkpd
systemctl reboot
```

Use `boot`, not `switch`, this first time: the display manager changes from
SDDM to ly, and switching live would end the Plasma session.

**If it goes wrong:** pick the previous generation in the systemd-boot menu.

## 2. First login

Log in at ly (mango is the only session). Then:

```sh
systemctl --user status noctalia bitwarden    # both should be active (mango)
ls ~/*.hm-backup ~/.config/**/*.hm-backup 2>/dev/null   # files HM replaced
```

If Noctalia is missing:

```sh
journalctl --user -u noctalia -b
systemctl --user status mango-session.target graphical-session.target
mango -p                                      # validate ~/.config/mango/config.toml
noctalia config validate ~/.config/noctalia/config.toml
```

## 3. Bitwarden SSH agent

Unlock Bitwarden from the tray, then:

```sh
echo $SSH_AUTH_SOCK                           # ~/.bitwarden-ssh-agent.sock
ssh-add -l                                    # must list a key
```

"The agent has no identities" means the vault's SSH key failed to parse
(see `~/.config/Bitwarden/app.log`). Fix it in Bitwarden:

- Edit the SSH key item → **Import key from clipboard** (copy the whole
  private key file), **or**
- New item → **SSH key** (generates ed25519).

Then add the public key to GitHub as both an **Authentication** and a **Signing** key:

```sh
ssh-add -L | head -n1                         # public key to paste
gh auth login                                 # if gh isn't set up yet
ssh-add -L | head -n1 > /tmp/k.pub
gh ssh-key add /tmp/k.pub --type authentication --title tkpd-bitwarden
gh ssh-key add /tmp/k.pub --type signing        --title tkpd-bitwarden
ssh -T git@github.com                         # "Hi osdva! ..."
```

If it's a new key, add it to `home/git.nix` → `allowedSigners` and to
`hosts/*/authorized_keys` (`curl -fsSL https://github.com/osdva.keys`).

Test signing:

```sh
cd ~/dev/nix
git commit --allow-empty -m "test signing" && git log --show-signature -1
git reset --hard HEAD~1
```

## 4. API keys (rbw)

In Bitwarden, create an item **`API-Keys`** with custom fields
`OPENCODE_API_KEY`, `EXA_API_KEY` (and any others). Then:

```sh
rbw unlock                                    # first time only: GNOME prompt, stored in the login keyring
rbw sync
rbw get --field EXA_API_KEY API-Keys          # should print the key
```

`rbw unlock: ... api request returned error: 400` (`agent.err` in
`~/.local/share/rbw/` says "New device verification required"): Bitwarden wants
an email code rbw can't handle. Run `rbw register` once per machine with the
personal API key (vault.bitwarden.eu → Settings → Security → Keys → API key),
then `rbw unlock`. Enabling two-step login on the account avoids the check too.

## 5. Hibernation

```sh
cat /sys/power/disk                           # [platform] shutdown ... (not [disabled])
cat /proc/cmdline | tr ' ' '\n' | grep resume # resume=/dev/disk/by-uuid/3997f049-...
systemctl hibernate                           # should come back with your windows open
```

Then try the lid, the power key, and Noctalia's session menu → **Hibernate**.

If the menu entry does nothing, check:

```sh
journalctl --user -u noctalia -b | grep -i -E "session|action|hibernate"
```

## 6. Coding agents

```sh
claude                                        # log in once
pi                                            # first run installs its npm: packages
cat ~/.claude/settings.json                   # theme/model merged in
ls ~/.pi/agent                                # agents extensions mcp.json models.json prompts settings.json
```

## 7. Neovim

```sh
nvim                                          # vim.pack installs plugins, Mason installs LSPs
git -C ~/dev/nix diff files/nvim/nvim-pack-lock.json   # plugin updates land in the repo
```

## 8. Fingerprint (system + Bitwarden)

Reader: Goodix `27c6:6594` (fprintd). Declared in `roles/workstation.nix`:
fingerprint for **sudo**, **polkit** (which includes Bitwarden) and the
Noctalia **lock screen**; never for the **ly login**, because the
keyring needs your password.

Enroll (touch the sensor repeatedly until it says `enroll-completed`):

```sh
fprintd-enroll -f right-index-finger
fprintd-enroll -f left-index-finger           # a second finger is a good backup
fprintd-list $USER                            # lists the enrolled fingers
fprintd-verify                                # test: touch the sensor
sudo true                                     # should ask for a finger, then fall back to password
```

Bitwarden (the polkit policy `com.bitwarden.Bitwarden.policy` is installed by
the package; nothing to copy):

1. Unlock the vault once with the master password.
2. Settings → Security → **Unlock with system authentication** → on.
3. Lock the vault (`Ctrl+L`), then click **Unlock with system authentication**
   and touch the sensor (the polkit prompt comes from Noctalia).

After a Bitwarden restart, it asks for the master password once before
fingerprint works again; that's Bitwarden's Linux behaviour.

Remove a finger: `fprintd-delete $USER` (deletes all of them; then re-enroll).

## 9. Make /etc/nixos point at the repo

```sh
sudo mv /etc/nixos /etc/nixos.bak
sudo mkdir /etc/nixos
sudo ln -s /home/osdva/dev/nix/flake.nix /etc/nixos/flake.nix
sudo nixos-rebuild build                      # plain command now finds #tkpd
# later, when happy:
sudo rm -rf /etc/nixos.bak
```

## 10. Leftovers from the old setup

```sh
rm -rf ~/.config/mise ~/.local/share/mise     # mise is gone; toolchains come from Nix
ls ~/.config/autostart                        # bitwarden.desktop is now a Hidden=true stub
```

## 11. Commit and push

```sh
cd ~/dev/nix
git status
git add -A
git commit -m "Multi-host flake: mango + Noctalia v5, ly, hibernate, Bitwarden agent, nh"
git push                                      # over SSH once step 3 works
```

The repo is private: keep it private, and keep secrets out of it.

## Day to day

```sh
udot                         # nh os switch: rebuild this host from ~/dev/nix
dot                          # open the repo in nvim
nh os switch --update        # update all inputs + switch (commit flake.lock)
nh os boot                   # apply on next boot (kernel, login manager)
nh search <pkg>              # search nixpkgs
nh clean all --keep 5        # manual cleanup (weekly: keep 5 / 7 days)
sudo nixos-rebuild switch --rollback          # undo the last switch
nix fmt                      # format .nix files
noctalia config export merged # Settings-UI changes, to copy into files/noctalia/config.toml
```

New project toolchain:

```sh
nix flake init -t ~/dev/nix#node   # or #python, #go, #devshell
direnv allow
```

New machine: `docs/hosts.md` (existing NixOS) or `docs/new-machine.md` (fresh install).

## Open decisions

- Extras not set up yet: sops-nix, disko, nix-index + comma (`docs/future.md`).
