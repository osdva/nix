# Portable machine: hibernation, lid/power-key behaviour, battery power saving.
# The host must point boot.resumeDevice at a swap partition >= RAM.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  # power-profiles-daemon only lowers EPP on battery; switch the whole profile
  # (EPP + firmware platform_profile) so unplugging really means power-saver.
  powerProfileAuto = pkgs.writeShellScript "power-profile-auto" ''
    online=0
    for ac in /sys/class/power_supply/*; do
      [ "$(cat "$ac/type")" = Mains ] && [ "$(cat "$ac/online")" = 1 ] && online=1
    done
    if [ "$online" = 1 ]; then profile=balanced; else profile=power-saver; fi
    exec ${lib.getExe' pkgs.power-profiles-daemon "powerprofilesctl"} set "$profile"
  '';
in
{
  assertions = [
    {
      assertion = config.boot.resumeDevice != "";
      message = "laptop role: set boot.resumeDevice in hosts/${config.networking.hostName} for hibernation.";
    }
  ];

  services.logind.settings.Login = {
    HandlePowerKey = "hibernate";
    HandlePowerKeyLongPress = "poweroff";
    HandleLidSwitch = "hibernate";
    HandleLidSwitchExternalPower = "hibernate";
    HandleLidSwitchDocked = "ignore";
    InhibitDelayMaxSec = 5;
  };

  systemd.sleep.settings.Sleep = {
    AllowSuspend = "yes";
    AllowHibernation = "yes";
    AllowSuspendThenHibernate = "yes";
    HibernateMode = "shutdown";
    HibernateDelaySec = "15min";
  };

  # No thermald: on ThinkPads with DYTC it exits with "can't run on this
  # platform" and the firmware (platform_profile) handles thermals.

  # --- Battery power saving -----------------------------------------------------
  # Runs at boot (PPD restores the last profile, which may be stale) and from
  # udev whenever the charger is plugged or unplugged.
  systemd.services.power-profile-auto = {
    description = "Pick the power profile for the current power source";
    after = [ "power-profiles-daemon.service" ];
    requires = [ "power-profiles-daemon.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = powerProfileAuto;
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${lib.getExe' config.systemd.package "systemctl"} start --no-block power-profile-auto.service"
    # Let every PCI device runtime-suspend when idle (several default to "on").
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
  '';

  boot.kernelParams = [ "pcie_aspm.policy=powersupersave" ];

  networking.networkmanager.wifi.powersave = true;
}
