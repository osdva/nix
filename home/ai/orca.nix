# Orca desktop and its `orca` CLI. The Linux GUI binary is `orca-ide`; `orca`
# is the CLI, because GNOME's screen reader owns the bare name. Shared skills
# reach it through ~/.agents/skills (home/ai/default.nix).
{ llmAgents, ... }:
{
  home.packages = [ llmAgents.orca ];
}
