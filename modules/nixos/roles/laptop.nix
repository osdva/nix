# Portable machine: hibernation, lid/power-key behaviour, thermals.
# The host must point boot.resumeDevice at a swap partition >= RAM.
{ config, lib, ... }:
{
  assertions = [
    {
      assertion = config.boot.resumeDevice != "";
      message = "laptop role: set boot.resumeDevice in hosts/${config.networking.hostName} for hibernation.";
    }
  ];

  # The kernel disables hibernation while any process holds memfd_secret memory,
  # and Bitwarden Desktop uses it for its key ("Using memfd_secret for secure key
  # storage"), so with Bitwarden running /sys/power/disk shows [disabled].
  # Turning memfd_secret off makes Bitwarden fall back to the kernel keyring
  # (keyctl), which still keeps the key out of process memory.
  boot.kernelParams = [ "secretmem.enable=0" ];

  # Same policy as the Arch dotfiles (.cp/systemd/{logind,sleep}.conf.d).
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
