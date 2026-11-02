# Cloud drives: one FUSE mount per rclone remote. The remotes (OAuth token /
# Filen login) aren't in the repo: create them once with `rclone config`,
# named as below.
{ lib, pkgs, ... }:
let
  # FUSE mount of an rclone remote at ~/<dir>.
  rcloneMount = remote: dir: {
    Unit = {
      Description = "rclone mount of ${remote}: at ~/${dir}";
      ConditionPathExists = "%h/.config/rclone/rclone.conf";
    };
    Service = {
      Type = "notify";
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/${dir}";
      ExecStart = lib.concatStringsSep " " [
        "${lib.getExe pkgs.rclone} mount ${remote}: %h/${dir}"
        "--vfs-cache-mode writes"
        "--vfs-cache-max-age 1h"
        "--vfs-read-chunk-size 128M"
        "--vfs-read-chunk-size-limit off"
        "--buffer-size 256M"
        "--poll-interval 15s"
        "--dir-cache-time 1h"
        "--timeout 1h"
        "--umask 022"
      ];
      ExecStop = "/run/wrappers/bin/fusermount3 -u %h/${dir}";
      Restart = "on-failure";
      RestartSec = 10;
    };
    Install.WantedBy = [ "default.target" ];
  };
in
{
  systemd.user.services.rclone-gdrive = rcloneMount "gdrive" "google-drive";
  systemd.user.services.rclone-filen = rcloneMount "filen" "filen";
}
