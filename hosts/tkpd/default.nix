# ThinkPad T14 Gen 5 — Intel Core Ultra 5 135U (Meteor Lake), 64 GB RAM.
{
  inputs,
  pkgs,
  user,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t14
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    "${inputs.nixos-hardware}/common/cpu/intel/meteor-lake"
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Hibernation: the 68 GB swap partition (nvme0n1p3) is bigger than RAM.
  boot.resumeDevice = "/dev/disk/by-uuid/3997f049-5585-4e5f-a2de-068294f4c9c6";

  users.users.${user}.openssh.authorizedKeys.keyFiles = [ ./authorized_keys ];

  # First NixOS release installed on this machine. Never bump it.
  system.stateVersion = "26.05";
}
