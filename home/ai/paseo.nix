# Paseo daemon and CLI for orchestrating coding agents.
{ llmAgents, ... }:
{
  home.packages = [ llmAgents.paseo ];
}
