// Supplies the `linear` MCP server's bearer token from Bitwarden.
//
// OpenCode substitutes only `{env:NAME}` in MCP headers, so configuration cannot
// fetch the API key itself. This plugin reads it with `rbw` during setup and
// injects the header, keeping the key out of the config file and off disk.
//
// Requires the rbw agent to be unlocked. When it is locked or the entry is
// missing, the server stays configured but unauthenticated.
import { execFile } from "node:child_process"
import { promisify } from "node:util"

const run = promisify(execFile)

const SERVER = "linear"
// Convention (home/ai/default.nix): one custom field per key on "API-Keys".
const ITEM = "API-Keys"
const FIELD = "LINEAR_API_KEY"

async function readToken() {
  try {
    const { stdout } = await run("rbw", ["get", "--field", FIELD, ITEM], {
      timeout: 10_000,
      maxBuffer: 1024 * 1024,
    })
    const token = stdout.trim()
    return token || undefined
  } catch (error) {
    console.warn(`[linear-token] could not read ${FIELD} from Bitwarden: ${error.message}`)
    return undefined
  }
}

export default {
  id: "linear-token",
  async setup(ctx) {
    if (typeof ctx.mcp?.transform !== "function") return
    const token = await readToken()
    if (!token) return
    await ctx.mcp.transform((editor) => {
      if (!editor.get(SERVER)) return
      editor.update(SERVER, (server) => {
        server.headers = { ...(server.headers ?? {}), Authorization: `Bearer ${token}` }
      })
    })
  },
}
