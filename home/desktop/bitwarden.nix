# Bitwarden Desktop: password manager and the only SSH agent on graphical hosts.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  bitwardenSock = "${config.home.homeDirectory}/.bitwarden-ssh-agent.sock";

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
    inherit (bitwardenSettings) global_environment_environment;
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
  # `git push`. Unlock it with the fingerprint (docs/post-install.md).
  systemd.user.services.bitwarden = {
    Unit = {
      Description = "Bitwarden (password manager + SSH agent)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStartPre = "${applyBitwardenSettings}";
      ExecStart = lib.getExe pkgs.bitwarden-desktop;
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
}
