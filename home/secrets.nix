# Runtime secrets from Bitwarden via rbw, an unofficial Bitwarden client with
# an agent (like ssh-agent): `rbw unlock` once per session, then `rbw get` works
# in any shell or script without exporting a session token.
#
#   rbw get "Item name"                     # password
#   rbw get --field CONTEXT7_API_KEY API-Keys  # custom field
#   rbw sync                                # refresh after editing the vault
{ lib, pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "me@osdva.dev";
      base_url = "https://api.bitwarden.eu"; # EU cloud (rbw maps identity too)
      lock_timeout = 3600 * 8;
      pinentry = lib.mkDefault pkgs.pinentry-curses; # desktop.nix uses Qt
    };
  };
}
