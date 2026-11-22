# Antigravity CLI (binary: agy). Google sign-in happens once per machine, so
# only the package and the shared skills are declared here.
{ agentSkillsTree, llmAgents, ... }:
{
  programs.antigravity-cli = {
    enable = true;
    package = llmAgents.antigravity-cli;
    # Same skills as opencode, pi and Claude Code, flattened from the pack folders.
    skills = agentSkillsTree;
  };
}
