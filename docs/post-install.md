# Post-install

What to do after the first boot of a machine built from this flake
(`docs/new-machine.md` or `docs/hosts.md`). Run the steps in order.

## 1. First login

Log in at ly (niri is the only session). Then:

```sh
systemctl --user status noctalia bitwarden    # both should be active
```

If Noctalia is missing:

```sh
journalctl --user -u noctalia -b
systemctl --user status niri graphical-session.target
niri validate                                 # validate ~/.config/niri/config.kdl
noctalia config validate ~/.config/noctalia/config.toml
```

## 2. Bitwarden SSH agent

Log in to Bitwarden and unlock it from the tray, then:

```sh
echo $SSH_AUTH_SOCK                           # ~/.bitwarden-ssh-agent.sock
ssh-add -l                                    # must list a key
ssh -T git@github.com                         # "Hi osdva! ..."; Bitwarden asks to approve
```

"The agent has no identities" with the vault unlocked means the SSH key item
failed to parse. `~/.config/Bitwarden/app.log` says `Skipping un-parseable key`.
Never paste a private key into the item by hand: line breaks or spaces break it.
Create the item with **New → SSH key → Import key from clipboard** (an icon next
to the private key field) after copying the key file:

```sh
wl-copy --sensitive < key && wl-copy --clear  # clear once Bitwarden has it
```

A new key goes on GitHub as both an **Authentication** and a **Signing** key,
and into `keys/osdva.pub`, which feeds SSH login on every host and git's
allowed signers.

Commits are SSH-signed with the first key in the agent. Check:

```sh
git log --show-signature -1                   # Good "git" signature ...
```

## 3. API keys (rbw)

Keys live in the Bitwarden item **`API-Keys`**, one custom field each
(`OPENCODE_API_KEY`, `EXA_API_KEY`, `CONTEXT7_API_KEY`, ...).

```sh
rbw register                                  # once per machine, see below
rbw unlock                                    # first time: GNOME prompt, stored in the login keyring
rbw get --field EXA_API_KEY API-Keys          # should print the key
```

Bitwarden asks new devices for an email code, which rbw can't handle: without
`rbw register`, `rbw unlock` fails with `api request returned error: 400`
(`~/.local/share/rbw/agent.err` says "New device verification required").
`rbw register` asks for the personal API key from vault.bitwarden.eu →
Settings → Security → Keys → API key.

After the first unlock, the `rbw-unlock` user service unlocks rbw silently at
every login. `rbw-pinentry-keyring clear` removes the stored password.

## 4. Fingerprint

Declared in `roles/workstation.nix`: fingerprint for **sudo**, **polkit**
(which includes Bitwarden) and the Noctalia **lock screen**; never for the
**ly login**, because the keyring needs your password.

```sh
fprintd-enroll -f right-index-finger          # touch until enroll-completed
fprintd-enroll -f left-index-finger           # a second finger as backup
fprintd-verify
sudo true                                     # asks for a finger, falls back to password
```

Bitwarden: Settings → Security → **Unlock with system authentication** → on.
After a Bitwarden restart it asks for the master password once before the
fingerprint works again.

## 5. Cloud drives (rclone)

`home/desktop/rclone.nix` mounts the rclone remotes `gdrive` at `~/google-drive` and
`filen` at `~/filen`. The units stay inactive until `rclone.conf` exists.
Create the remotes with `rclone config`:

- **filen**: type `filen`, email, password and an API key from
  `nix run nixpkgs#filen-cli -- export-api-key` (run it in your own terminal;
  then `rm -rf ~/.config/filen-cli`).
- **gdrive**: type `drive`, scope `1`, browser login. Use your own OAuth client:
  rclone's shared one is being retired. In console.cloud.google.com: new
  project → enable **Google Drive API** → **Google Auth Platform**: branding
  (app name, support and developer email, home page and privacy link on
  osdva.dev, authorized domain `osdva.dev`, **no logo**), scope `…/auth/drive`,
  **Audience → Publish app** (in Testing the login expires after 7 days) →
  **Clients → Desktop app**. Paste its client ID and secret into rclone.

```sh
systemctl --user start rclone-gdrive rclone-filen
ls ~/google-drive ~/filen
```

## 6. Hibernation

```sh
cat /sys/power/disk                           # [platform] shutdown ... (not [disabled])
systemctl hibernate                           # should come back with your windows open
```

Then try the lid, the power key, and Noctalia's session menu → **Hibernate**.

## 7. Coding agents and Neovim

```sh
claude                                        # log in once
pi                                            # first run installs its npm: packages
nvim                                          # vim.pack installs plugins, Mason installs LSPs
```

## 8. /etc/nixos

Point `/etc/nixos` at the repo, so a plain `nixos-rebuild` finds this host:

```sh
sudo rm -rf /etc/nixos && sudo mkdir /etc/nixos
sudo ln -s ~/dev/nix/flake.nix /etc/nixos/flake.nix
```

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
noctalia config export merged # Settings-UI changes, to copy into home/desktop/noctalia.nix
```
