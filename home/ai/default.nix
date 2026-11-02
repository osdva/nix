# Coding agents: Claude Code, pi and opencode. Imported by home/development.
#
# API keys are never in this repo: they're read from Bitwarden at runtime with
# rbw (home/secrets.nix). Convention: one Bitwarden item "API-Keys" with one
# custom field per key (OPENCODE_API_KEY, EXA_API_KEY, ...):
#   rbw get --field OPENCODE_API_KEY API-Keys
# `rbwSecret "FIELD"` builds that command for the modules below.
{
  imports = [
    ./claude-code.nix
    ./opencode.nix
    ./pi.nix
  ];

  _module.args.rbwSecret = field: "rbw get --field ${field} API-Keys";
}
