# ThinkPad T14 Gen 5 — Intel Core Ultra 5 135U (Meteor Lake), 64 GB RAM.
{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    # nixos-hardware has no T14 Intel Gen 5 profile (lenovo-thinkpad-t14 is
    # Gen 1 and adds its touchpad/backlight quirks), so compose the generic parts.
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad # trackpoint + common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
    "${inputs.nixos-hardware}/common/cpu/intel/meteor-lake"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hibernation: the 68 GB swap partition (nvme0n1p3) is bigger than RAM.
  boot.resumeDevice = (builtins.head config.swapDevices).device;

  # Meteor Lake NPU (intel_vpu driver + firmware).
  hardware.cpu.intel.npu.enable = true;

  # First NixOS release installed on this machine. Never bump it.
  system.stateVersion = "26.05";
}
