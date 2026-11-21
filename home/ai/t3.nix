# T3 Code: the `t3` server/CLI and the desktop control surface.
{ llmAgents, ... }:
{
  home.packages = [
    llmAgents.t3code
    llmAgents.t3code-desktop
  ];
}
