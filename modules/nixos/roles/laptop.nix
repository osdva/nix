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

  # Firmware exposes PL1 == PL2 == 57 W on this 15 W-class Meteor Lake part, so the
  # package can burn full turbo power indefinitely. With a few busy threads that
  # parks the package at ~70 °C and pushes the adjacent DDR5 SODIMM past its own
  # 55 °C "high" threshold. PPD only toggles EPP/platform_profile, never RAPL, so
  # the power limit needs clamping explicitly.
  cpuPowerCap = pkgs.writeShellScript "cpu-power-cap" ''
    set -u

    online=0
    for ac in /sys/class/power_supply/*; do
      [ "$(cat "$ac/type" 2>/dev/null)" = Mains ] && [ "$(cat "$ac/online" 2>/dev/null)" = 1 ] && online=1
    done

    if [ "$online" = 1 ]; then
      pl1=20000000  # 20 W sustained
      pl2=28000000  # 28 W burst
      peak=35000000
      perf=80       # % of max turbo
    else
      pl1=12000000
      pl2=18000000
      peak=25000000
      perf=60
    fi

    setval() {
      if [ -e "$1" ] && [ -w "$1" ]; then
        echo "$2" > "$1" 2>/dev/null \
          || echo "cpu-power-cap: write $2 -> $1 failed" >&2
      else
        echo "cpu-power-cap: $1 missing or not writable, skipping" >&2
      fi
    }

    # Ensure RAPL lock bit isn't set before touching the constraints.
    setval /sys/class/powercap/intel-rapl:0/enabled 1

    setval /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw "$pl1"
    setval /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw "$pl2"
    setval /sys/class/powercap/intel-rapl:0/constraint_2_power_limit_uw "$peak"
    setval /sys/devices/system/cpu/intel_pstate/max_perf_pct "$perf"
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
    # PPD itself is After=multi-user.target, WantedBy=graphical.target.
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = powerProfileAuto;
    };
  };

  # Clamp RAPL + max_perf_pct at boot and whenever the charger state changes.
  systemd.services.cpu-power-cap = {
    description = "Clamp CPU power limits for the current power source";
    after = [ "power-profiles-daemon.service" ];
    requires = [ "power-profiles-daemon.service" ];
    wantedBy = [ "graphical.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = cpuPowerCap;
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="power_supply", ATTR{type}=="Mains", RUN+="${lib.getExe' config.systemd.package "systemctl"} start --no-block power-profile-auto.service cpu-power-cap.service"
    # Let every PCI device runtime-suspend when idle (several default to "on").
    ACTION=="add", SUBSYSTEM=="pci", ATTR{power/control}="auto"
  '';

  boot.kernelParams = [ "pcie_aspm.policy=powersupersave" ];

  networking.networkmanager.wifi.powersave = true;
}
