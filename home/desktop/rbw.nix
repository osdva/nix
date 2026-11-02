# rbw (home/secrets.nix) gets the master password from the login keyring
# (unlocked by ly at login) via upstream's rbw-pinentry-keyring. The first
# unlock shows one GNOME prompt and stores the password there; after that rbw
# unlocks silently. Forget it: `rbw-pinentry-keyring clear`.
{
  config,
  lib,
  pkgs,
  ...
}:
let
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
in
{
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
      ExecStart = "${lib.getExe config.programs.rbw.package} unlock";
      RemainAfterExit = true;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
