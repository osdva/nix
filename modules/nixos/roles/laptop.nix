# Portable machine: hibernation, lid/power-key behaviour, thermals.
# The host must point boot.resumeDevice at a swap partition >= RAM.
{ config, ... }:
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

  services.thermald.enable = true;
}
