# Windscribe GUI, started quiet at login so it sits in the tray. The privileged
# half (helper daemon, setgid engine wrapper, firewall/DNS scripts) is
# services.windscribe in the workstation role; the Home Manager module only
# adds the package to this user.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  # Built against the windscribe flake's own nixpkgs pin; see flake.nix.
  windscribe = inputs.windscribe.packages.${pkgs.stdenv.hostPlatform.system}.windscribe;
in
{
  imports = [ inputs.windscribe.homeManagerModules.windscribe ];

  programs.windscribe = {
    enable = true;
    package = windscribe;
  };

  # Not programs.windscribe.autoStart: that runs the bare binary, which opens
  # the window. Upstream's own startup entry adds `--autostart`, which starts it
  # hidden in the tray; this unit is that entry, managed by systemd.
  systemd.user.services.windscribe = {
    Unit = {
      Description = "Windscribe tray";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${lib.getExe windscribe} --autostart";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
