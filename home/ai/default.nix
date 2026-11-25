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
  # Source packs keep their upstream folder layout; agents get one flat entry
  # per SKILL.md directory.
  discoverSkills =
    dir:
    lib.concatLists (
      lib.mapAttrsToList (
        name: type:
        if lib.hasPrefix "." name then
          [ ]
        else
          let
            path = dir + "/${name}";
          in
          if type == "directory" then
            (
              if builtins.pathExists (path + "/SKILL.md") then
                [
                  {
                    inherit name;
                    source = path;
                  }
                ]
              else
                discoverSkills path
            )
          else
            [ ]
      ) (builtins.readDir dir)
    );
  agentSkills =
    let
      discovered = discoverSkills skillsDir;
      names = map (s: s.name) discovered;
      duplicates = lib.subtractLists (lib.unique names) names;
    in
    assert lib.assertMsg (
      duplicates == [ ]
    ) "duplicate skill names: ${lib.concatStringsSep ", " duplicates}";
    discovered;
  agentSkillsTree = pkgs.linkFarm "agent-skills" (
    map (s: {
      inherit (s) name;
      path = s.source;
    }) agentSkills
    ++ [
      {
        name = "LICENSE.mattpocock-skills.md";
        path = skillsDir + "/matt/LICENSE";
      }
      {
        name = "LICENSE.uphiago-recon-skills.md";
        path = skillsDir + "/uphiago/LICENSE";
      }
      {
        name = "LICENSE.pstack.md";
        path = skillsDir + "/pstack/LICENSE";
      }
      {
        name = "LICENSE.emil-skills.md";
        path = skillsDir + "/emil/LICENSE";
      }
    ]
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
  # RTK (token-reduction proxy) generates its per-agent hooks, plugins and rules
  # with the pinned llmAgents.rtk.
  rtkInit = pkgs.runCommandLocal "rtk-init-${llmAgents.rtk.version}" { } ''
    export HOME="$TMPDIR/home"
    export XDG_CONFIG_HOME="$HOME/.config"
    mkdir -p "$HOME" "$XDG_CONFIG_HOME"
    ${lib.getExe llmAgents.rtk} init -g --opencode --auto-patch </dev/null >/dev/null 2>&1 || true
    ${lib.getExe llmAgents.rtk} init -g --agent pi --auto-patch </dev/null >/dev/null 2>&1 || true
    ${lib.getExe llmAgents.rtk} init -g --agent antigravity --auto-patch </dev/null >/dev/null 2>&1 || true
    ${lib.getExe llmAgents.rtk} init -g --codex </dev/null >/dev/null 2>&1 || true
    mkdir -p "$out"
    cp -r "$HOME/." "$out/"
  '';
in
{
  imports = [
    ./agy.nix
    ./claude-code.nix
    ./codex.nix
    ./opencode.nix
    ./orca.nix
    ./paseo.nix
    ./pi.nix
    ./t3.nix
  ];

  _module.args = {
    rbwSecret = field: "rbw get --field ${field} API-Keys";
    inherit
      agentSkills
      agentSkillsTree
      llmAgents
      opencodeCli
      rtkInit
      ;
  };

  home.packages = [
    llmAgents.rtk
  ];

  # opencode and Orca both discover ~/.agents/skills. Link each shared skill
  # individually so entries they manage themselves stay untouched.
  home.file = lib.listToAttrs (
    map (s: {
      name = ".agents/skills/${s.name}";
      value.source = s.source;
    }) agentSkills
  );
}
