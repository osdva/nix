# Antigravity CLI (binary: agy). Google sign-in happens once per machine.
{
  agentSkillsTree,
  llmAgents,
  rtkInit,
  ...
}:
{
  programs.antigravity-cli = {
    enable = true;
    package = llmAgents.antigravity-cli;
    # Same skills as opencode, pi and Claude Code.
    skills = agentSkillsTree;
  };

  home.file.".gemini/config/plugins/rtk".source = "${rtkInit}/.gemini/config/plugins/rtk";
}
