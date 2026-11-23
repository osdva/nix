# OpenAI Codex CLI (binary: codex). Sign-in happens interactively via `codex`
# or through Orca.
{
  llmAgents,
  rtkInit,
  ...
}:
{
  programs.codex = {
    enable = true;
    package = llmAgents.codex;
    mutableSettings = true;
    settings = {
      features.hooks = true;
    };
    hooks.PreToolUse = [
      {
        matcher = "Bash";
        hooks = [
          {
            type = "command";
            command = "rtk hook codex";
          }
        ];
      }
    ];
  };

  home.file.".codex/AGENTS.md".source = "${rtkInit}/.codex/RTK.md";
}
