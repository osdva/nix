# Git with SSH commit signing. The key comes from whatever agent is in
# SSH_AUTH_SOCK (Bitwarden on workstations, a forwarded agent on servers),
# so no private key or key path is hardcoded here.
{ lib, pkgs, ... }:
let
  email = "arthurvdinizs@gmail.com";
  # Public keys allowed to sign as me; used by `git log --show-signature`.
  # Same keys that may SSH into every host (keys/osdva.pub).
  allowedSigners = pkgs.writeText "allowed_signers" (
    lib.concatMapStrings (key: "${email} ${key}\n") (
      lib.filter (line: line != "") (lib.splitString "\n" (builtins.readFile ../keys/osdva.pub))
    )
  );
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
        inherit email;
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
