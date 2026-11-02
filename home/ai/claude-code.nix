{
  programs.claude-code = {
    enable = true;
    # Claude Code also writes settings (/model, /config): merge declared keys
    # into a writable ~/.claude/settings.json instead of a read-only link.
    mutableSettings = true;
    settings = {
      theme = "dark-daltonized";
      model = "opus";
    };
  };
}
