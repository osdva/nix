# IVPN GUI, started hidden at login so it sits in the tray (connect/disconnect
# from its menu). The daemon is services.ivpn in the workstation role.
{ lib, pkgs, ... }:
{
  home.packages = [ pkgs.ivpn-ui ];

  # `--hidden` + the app's "minimize to tray" setting (on by default) = tray only.
  systemd.user.services.ivpn-ui = {
    Unit = {
      Description = "IVPN tray";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe pkgs.ivpn-ui} --hidden";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
