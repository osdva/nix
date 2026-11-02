# Git with SSH commit signing. The key comes from whatever agent is in
# SSH_AUTH_SOCK (Bitwarden on workstations, a forwarded agent on servers),
# so no private key or key path is hardcoded here.
{ pkgs, ... }:
let
  # Public keys allowed to sign as me; used by `git log --show-signature`.
  allowedSigners = pkgs.writeText "allowed_signers" ''
    arthurvdinizs@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfy+S7oSVnyEmriEYXcVM1Y6rLKWh/XNFVy96Oaz1nu
    arthurvdinizs@gmail.com ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGHh2/DfPI+gJl2hEIh4hak/CdfISyrdKvrkSIthWkUD
  '';
in
{
  programs.git = {
    enable = true;
    signing = {
      format = "ssh";
      signByDefault = true;
      # null key → git asks gpg.ssh.defaultKeyCommand (first key in the agent).
      key = null;
    };
    settings = {
      user = {
        name = "Arthur Diniz";
        email = "arthurvdinizs@gmail.com";
      };
      core.editor = "nvim";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      diff.external = "difft";
      gpg.ssh = {
        defaultKeyCommand = "sh -c 'echo key::$(ssh-add -L | head -n1)'";
        allowedSignersFile = "${allowedSigners}";
      };
      url."git@github.com:".pushInsteadOf = "https://github.com/";
    };
  };
}
