# Coding agents: Claude Code, pi, opencode, Antigravity CLI, Orca and T3 Code.
# Imported by home/development.
#
# API keys are never in this repo: they're read from Bitwarden at runtime with
# rbw (home/secrets.nix). Convention: one Bitwarden item "API-Keys" with one
# custom field per key (OPENCODE_API_KEY, EXA_API_KEY, LINEAR_API_KEY, ...):
#   rbw get --field OPENCODE_API_KEY API-Keys
# `rbwSecret "FIELD"` builds that command for the modules below.
{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  skillsDir = ../../files/skills;
  skillNames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir skillsDir)
  );
  # Pinned by flake.lock; update with `nix flake update llm-agents`.
  llmAgents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};
  # llm-agents ships OpenCode 2 as `opencode2` so it can coexist with the v1
  # `opencode`. Expose v2 under the plain command name: existing sessions and
  # ~/.config/opencode/cli.json use the v2 schema, which v1 cannot open.
  opencodeCli =
    pkgs.runCommandLocal "opencode-${llmAgents.opencode2.version}"
      {
        meta.mainProgram = "opencode";
      }
      ''
        mkdir -p $out/bin
        ln -s ${lib.getExe llmAgents.opencode2} $out/bin/opencode
      '';
in
{
  imports = [
    ./agy.nix
    ./claude-code.nix
    ./opencode.nix
    ./orca.nix
    ./pi.nix
    ./t3.nix
  ];

  _module.args = {
    rbwSecret = field: "rbw get --field ${field} API-Keys";
    inherit llmAgents opencodeCli;
  };

  # opencode and Orca both discover ~/.agents/skills. Link each shared skill
  # individually so entries they manage themselves stay untouched.
  home.file = lib.listToAttrs (
    map (name: {
      name = ".agents/skills/${name}";
      value.source = skillsDir + "/${name}";
    }) skillNames
  );
}
