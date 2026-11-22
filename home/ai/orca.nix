# Orca desktop and its `orca` CLI. The Linux GUI binary is `orca-ide`; `orca`
# is the CLI, because GNOME's screen reader owns the bare name. Shared skills
# reach it through ~/.agents/skills (home/ai/default.nix).
#
# Orca bundles no providers: it detects agent CLIs on PATH. The agents it
# should use (opencode, Claude Code, pi, Antigravity) are installed by their
# own modules; Codex is deliberately not installed.
{ llmAgents, ... }:
{
  home.packages = [ llmAgents.orca ];
}
