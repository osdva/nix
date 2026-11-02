# Noctalia v5 shell (bar, launcher, lock screen, idle, wallpaper). Imported by
# home/desktop. Written to ~/.config/noctalia/config.toml (read-only) and
# validated at build time. Changes made in the Settings UI are saved as
# overrides in the state dir; `noctalia config export merged` prints them so
# they can be copied back here.
{ config, lib, ... }:
let
  home = config.home.homeDirectory;
in
{
  programs.noctalia = {
    enable = true;
    systemd.enable = true;
    settings = {
      shell = {
        font_family = "Adwaita Sans";
        avatar_path = "${home}/Pictures/avatar.jpg";
        time_format = "{:%I:%M %p}";
        date_format = "%a, %b %d";
        telemetry_enabled = false;
        setup_wizard_enabled = false;
        polkit_agent = true;
        clipboard_enabled = true;

        launcher = {
          categories = true;
          sort_by_usage = true;
        };

        shadow.direction = "down_right";

        session = {
          show_shortcuts = true;
          actions = [
            {
              action = "lock";
              shortcut = "1";
            }
            {
              action = "lock_and_suspend";
              shortcut = "2";
            }
            {
              action = "command";
              command = "systemctl hibernate";
              label = "Hibernate";
              glyph = "hibernate";
              shortcut = "3";
            }
            {
              action = "reboot";
              shortcut = "4";
            }
            {
              action = "logout";
              shortcut = "5";
            }
            {
              action = "shutdown";
              shortcut = "6";
              variant = "destructive";
            }
          ];
        };
      };

      theme = {
        mode = "dark";
        source = "wallpaper";
        wallpaper_scheme = "m3-tonal-spot";
        builtin = "Kanagawa";
      };

      bar = {
        order = [ "default" ];
        default = {
          position = "top";
          background_opacity = 0.93;
          capsule = true;
          widget_spacing = 6;
          show_on_workspace_switch = true;
          start = [
            "workspaces"
            "active_window"
            "media"
          ];
          center = [
            "date"
            "thepunkoff/pomodoro:widget"
          ];
          end = [
            "tray"
            "notifications"
            "keyboard_layout"
            "cpu"
            "ram"
            "battery"
            "volume"
            "caffeine"
            "control-center"
          ];
        };
      };

      widget = {
        date = {
          type = "clock";
          format = "{:%I:%M %p  %a, %b %d}";
        };
        keyboard_layout = {
          type = "keyboard_layout";
          hide_when_single_layout = true;
        };
      };

      battery.warning_threshold = 20;

      audio = {
        enable_volume_sounds = false;
        enable_notification_sounds = false;
      };

      # Timeouts are floats in Noctalia's schema (seconds).
      idle = {
        behavior_order = [
          "screen-off"
          "lock"
          "hibernate"
        ];
        behavior = {
          screen-off = {
            action = "screen_off";
            enabled = true;
            timeout = 600.0;
          };
          lock = {
            action = "lock";
            enabled = true;
            timeout = 660.0;
          };
          hibernate = {
            action = "command";
            command = "systemctl hibernate";
            enabled = true;
            timeout = 1800.0;
          };
        };
      };

      # Fingerprint unlock goes through fprintd directly (not PAM). It doesn't
      # arm when the lock screen is already up at resume; type the password there.
      lockscreen = {
        enabled = true;
        fingerprint = true;
        lock_before_suspend = true;
      };

      location = {
        auto_locate = false;
        address = "Curitiba";
      };

      weather = {
        enabled = true;
        effects = false;
        unit = "metric";
      };

      nightlight = {
        enabled = false;
        temperature_day = 6500;
        temperature_night = 4000;
      };

      notification.position = "top_right";

      osd = {
        position = "top_right";
        hide_delay_ms = 2000;
      };

      wallpaper = {
        enabled = true;
        directory = "${home}/Pictures/wallpapers";
        fill_mode = "crop";
        transition = [
          "disc"
          "wipe"
          "fade"
        ];
        transition_duration = 1500.0;
        transition_on_startup = false;
      };

      desktop_widgets.enabled = false;

      control_center.shortcuts = map (type: { inherit type; }) [
        "wifi"
        "bluetooth"
        "notification"
        "power_profile"
        "caffeine"
        "nightlight"
      ];

      plugins.enabled = [ "thepunkoff/pomodoro" ];
    };
  };

  # Directories the config above points at.
  home.activation.noctaliaDirs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${home}/Pictures/wallpapers" "${home}/Pictures/Screenshots"
  '';
}
