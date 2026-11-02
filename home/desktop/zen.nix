# Zen browser (beta channel) from the zen-browser flake. Default browser;
# Firefox stays installed (workstation role).
{ inputs, pkgs, ... }:
let
  bitwardenExtension = "{446900e4-71c2-419f-a6a7-df9c091e268b}";

  # Native messaging bridge to the Bitwarden desktop app (browser biometrics
  # unlock). Same manifest Bitwarden writes for Firefox, but at a Nix path.
  bitwardenNativeHost =
    pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/com.8bit.bitwarden.json"
      (
        builtins.toJSON {
          name = "com.8bit.bitwarden";
          description = "Bitwarden desktop <-> browser bridge";
          path = "${pkgs.bitwarden-desktop}/libexec/desktop_proxy";
          type = "stdio";
          allowed_extensions = [ bitwardenExtension ];
        }
      );
in
{
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;
    nativeMessagingHosts = [ bitwardenNativeHost ];

    # Extensions are installed from addons.mozilla.org via policies (keyed by
    # add-on ID) and kept installed; Zen updates them itself.
    policies.ExtensionSettings =
      builtins.mapAttrs
        (_: slug: {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/${slug}/latest.xpi";
          installation_mode = "force_installed";
        })
        {
          ${bitwardenExtension} = "bitwarden-password-manager";
        };
  };

  # The wrapper links native hosts into ~/.mozilla, but Gecko in XDG mode (Zen's
  # profile is in ~/.config/zen) reads $XDG_CONFIG_HOME/mozilla instead.
  xdg.configFile."mozilla/native-messaging-hosts/com.8bit.bitwarden.json" = {
    source = "${bitwardenNativeHost}/lib/mozilla/native-messaging-hosts/com.8bit.bitwarden.json";
    force = true;
  };
}
