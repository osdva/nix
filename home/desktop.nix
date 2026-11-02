# Home Manager for graphical hosts (imported by the workstation role).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  bitwardenSock = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

  # rbw ships this helper in its source tree but nixpkgs doesn't install it.
  # Falls back to pinentry-gnome3 when the keyring has no password yet.
  rbwPinentryKeyring =
    pkgs.runCommand "rbw-pinentry-keyring"
      {
        nativeBuildInputs = [ pkgs.makeWrapper ];
        meta.mainProgram = "rbw-pinentry-keyring";
      }
      ''
        install -Dm755 ${config.programs.rbw.package.src}/bin/rbw-pinentry-keyring $out/bin/rbw-pinentry-keyring
        patchShebangs $out/bin
        wrapProgram $out/bin/rbw-pinentry-keyring --prefix PATH : ${
          lib.makeBinPath [
            pkgs.libsecret
            pkgs.pinentry-gnome3 # GTK/Adwaita dialog via gcr (dbus prompter from gnome-keyring)
            pkgs.gnugrep
            pkgs.coreutils
          ]
        }
      '';

  # --- Bitwarden settings, declared ------------------------------------------
  # Bitwarden keeps settings and the encrypted vault cache together in
  # ~/.config/Bitwarden/data.json, so the file can't be a read-only symlink.
  # Instead these keys are merged into it before every Bitwarden start (and on
  # `udot` while it isn't running). Anything else stays app-managed.
  # Key names come from the app (StateDefinition "desktopSettings" / "environment").
  bitwardenSettings = {
    global_environment_environment = {
      region = "EU"; # vault.bitwarden.eu
      urls = null;
    };
    global_desktopSettings_sshAgentEnabled = true;
    global_desktopSettings_trayEnabled = true;
    global_desktopSettings_startToTray = true;
    global_desktopSettings_closeToTray = true;
    global_desktopSettings_minimizeToTray = true;
    # Started by the systemd unit below, not Bitwarden's own autostart file.
    global_desktopSettings_openAtLogin = false;
  };
  # Same server for the `bw` CLI.
  bitwardenCliSettings = {
    global_environment_environment = bitwardenSettings.global_environment_environment;
  };

  applyBitwardenSettings = pkgs.writeShellScript "bitwarden-apply-settings" ''
    set -eu
    merge() {
      file="$1"; settings="$2"
      mkdir -p "$(dirname "$file")"
      if [ ! -s "$file" ]; then
        # First run: let the app create its own state file.
        return 0
      fi
      tmp="$(mktemp "$file.XXXXXX")"
      ${lib.getExe pkgs.jq} -s '.[0] * .[1]' "$file" "$settings" > "$tmp"
      chmod 600 "$tmp"
      mv "$tmp" "$file"
    }
    merge "$HOME/.config/Bitwarden/data.json" ${pkgs.writeText "bitwarden.json" (builtins.toJSON bitwardenSettings)}
    merge "$HOME/.config/Bitwarden CLI/data.json" ${pkgs.writeText "bitwarden-cli.json" (builtins.toJSON bitwardenCliSettings)}
  '';
in
{
  # --- Bitwarden as the SSH agent -------------------------------------------
  # The settings above enable the agent; it serves the SSH keys stored in the
  # vault on the socket below once the vault is unlocked. Every shell, systemd
  # user unit and GUI app gets it through SSH_AUTH_SOCK, and ssh itself is
  # pinned to it via IdentityAgent.
  home.sessionVariables.SSH_AUTH_SOCK = bitwardenSock;
  systemd.user.sessionVariables.SSH_AUTH_SOCK = bitwardenSock;

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "github.com" = {
        HostName = "github.com";
        User = "git";
      };
      # Catch-all last: ssh uses the first value it finds for each option.
      "*" = lib.hm.dag.entryAfter [ "github.com" ] {
        IdentityAgent = bitwardenSock;
        ServerAliveInterval = 60;
      };
    };
  };

  # Start Bitwarden with the session so the SSH agent is there when you first
  # `git push`. Unlock it with the fingerprint (docs/next-steps.md step 8).
  systemd.user.services.bitwarden = {
    Unit = {
      Description = "Bitwarden (password manager + SSH agent)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${applyBitwardenSettings}";
      ExecStart = "${pkgs.bitwarden-desktop}/bin/bitwarden";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # Apply settings on rebuild too, but never under a running Bitwarden
  # (it would overwrite the file from memory on exit).
  home.activation.bitwardenSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ! ${pkgs.procps}/bin/pgrep -u "$USER" -f 'Bitwarden/bitwarden' >/dev/null; then
      run ${applyBitwardenSettings}
    fi
  '';

  # Mask the autostart entry Bitwarden wrote itself, so an XDG-autostart-aware
  # session doesn't start a second copy next to the systemd unit.
  xdg.configFile."autostart/bitwarden.desktop" = {
    force = true;
    text = ''
      [Desktop Entry]
      Type=Application
      Name=Bitwarden
      Hidden=true
    '';
  };

  # rbw (home/secrets.nix) gets the master password from the login keyring
  # (unlocked by ly at login) via upstream's rbw-pinentry-keyring. The first
  # unlock shows one GNOME prompt and stores the password there; after that rbw
  # unlocks silently. Forget it: `rbw-pinentry-keyring clear`.
  programs.rbw.settings.pinentry = rbwPinentryKeyring;
  home.packages = [ rbwPinentryKeyring ];

  # Unlock rbw right after login (silent once the password is in the keyring),
  # so API keys work in every shell for lock_timeout (8 h).
  systemd.user.services.rbw-unlock = {
    Unit = {
      Description = "Unlock rbw (Bitwarden CLI agent) from the login keyring";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${config.programs.rbw.package}/bin/rbw unlock";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  # --- mango -------------------------------------------------------------------
  xdg.configFile."mango/config.toml".source = ../files/mango/config.toml;

  # Units tied to config.wayland.systemd.target (Noctalia) start only in mango.
  wayland.systemd.target = "mango-session.target";

  # --- Noctalia v5 ------------------------------------------------------------
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = ../files/noctalia/config.toml; # validated at build time
  };

  # --- Terminals ---------------------------------------------------------------
  xdg.configFile."kitty/kitty.conf".source = ../files/kitty/kitty.conf;
  xdg.configFile."kitty/current-theme.conf".source = ../files/kitty/current-theme.conf;
  xdg.configFile."ghostty/config".source = ../files/ghostty/config;
  xdg.configFile."ghostty/themes/Kanagawa Dragon".source = ../files/ghostty/themes + "/Kanagawa Dragon";

  # --- Look & feel -------------------------------------------------------------
  home.pointerCursor = {
    enable = true;
    package = pkgs.adwaita-icon-theme;
    name = "Adwaita";
    size = 24;
    gtk.enable = true;
  };
  # Owns gtk-{3,4}.0/settings.ini and the matching dconf keys (what the settings
  # portal hands to GTK4 apps like Nautilus), replacing Plasma's breeze leftovers.
  # No theme/extraCss, so gtk.css stays Noctalia's.
  gtk = {
    enable = true;
    iconTheme = {
      package = pkgs.adwaita-icon-theme;
      name = "Adwaita";
    };
    font = {
      name = "Adwaita Sans";
      size = 11;
    };
  };
  dconf.settings."org/gnome/desktop/interface" = {
    color-scheme = "prefer-dark";
    document-font-name = "Adwaita Sans 11";
    monospace-font-name = "CommitMono Nerd Font 11";
  };

  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "application/pdf" = "org.kde.okular.desktop";
      "image/png" = "org.gnome.Loupe.desktop";
      "image/jpeg" = "org.gnome.Loupe.desktop";
      "inode/directory" = "org.gnome.Nautilus.desktop";
    };
  };

  # Directories Noctalia's config points at.
  home.activation.noctaliaDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Pictures/wallpapers" "$HOME/Pictures/Screenshots"
  '';
}
