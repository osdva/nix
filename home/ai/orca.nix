# Orca desktop and its `orca` CLI. The Linux GUI binary is `orca-ide`; `orca`
# is the CLI, because GNOME's screen reader owns the bare name. Shared skills
# reach it through ~/.agents/skills (home/ai/default.nix).
#
# Orca bundles no providers: it detects agent CLIs on PATH; they are installed
# by their own modules.
#
# Command Code is installed here because Orca's picker detects `command-code`.
# The CLI does not expand the lazy `!command` key pi writes to
# ~/.commandcode/auth.json, so the wrapper below supplies the same Bitwarden
# key through COMMAND_CODE_API_KEY for every invocation.
{
  pkgs,
  llmAgents,
  rbwSecret,
  ...
}:
let
  commandCode =
    pkgs.runCommandLocal "command-code-${llmAgents.command-code.version}"
      {
        meta.mainProgram = "command-code";
      }
      ''
        mkdir -p $out/bin
        cat > $out/bin/command-code <<'EOF'
        #!${pkgs.runtimeShell}
        if [ -z "''${COMMAND_CODE_API_KEY:-}" ] && rbw unlocked >/dev/null 2>&1; then
          key=$(${rbwSecret "COMMAND_CODE_API_KEY"} 2>/dev/null) || true
          if [ -n "$key" ]; then
            export COMMAND_CODE_API_KEY="$key"
          fi
        fi
        exec ${llmAgents.command-code}/bin/command-code "$@"
        EOF
        chmod +x $out/bin/command-code
        for bin in cmd cmdc commandcode; do
          ln -s command-code $out/bin/$bin
        done
      '';
in
{
  home.packages = [
    llmAgents.orca
    commandCode
  ];
}
