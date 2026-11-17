// Supplies the `baratorama-admin` MCP server's bearer token from Bitwarden.
//
// OpenCode substitutes only `{env:NAME}` in MCP headers, so configuration cannot
// fetch the token itself. This plugin reads it with `rbw` during setup and
// injects the header through the MCP transform, keeping the token out of the
// config file and off disk.
//
// Requires the rbw agent to be unlocked. When it is locked or the entry is
// missing, the server stays configured but unauthenticated, and
// `opencode mcp list` reports it as needing authentication.
import { execFile } from "node:child_process"
import { promisify } from "node:util"

const run = promisify(execFile)

const SERVER = "baratorama-admin"
// Convention (home/ai/default.nix): one custom field per key on "API-Keys".
const ITEM = "API-Keys"
const FIELD = "ADMIN_MCP_TOKEN"
// Today the token is the `ADMIN_MCP_TOKEN=` line in this item's notes.
const ENV_ITEM = "Baratorama VPS - backend.env"
const MIN_LENGTH = 32

async function rbw(args) {
  const { stdout } = await run("rbw", args, { timeout: 10_000, maxBuffer: 1024 * 1024 })
  return stdout
}

function tokenOf(value) {
  const token = value?.trim()
  return token && token.length >= MIN_LENGTH ? token : undefined
}

async function readToken() {
  try {
    const field = tokenOf(await rbw(["get", "--field", FIELD, ITEM]))
    if (field) return field
  } catch {
    // No such custom field yet; fall back to the notes below.
  }
  try {
    const text = await rbw(["get", ENV_ITEM, "--full"])
    const line = text.split(/\r?\n/).find((candidate) => candidate.startsWith(`${FIELD}=`))
    return tokenOf(line?.slice(FIELD.length + 1))
  } catch (error) {
    console.warn(`[baratorama-admin-token] could not read ${FIELD} from Bitwarden: ${error.message}`)
    return undefined
  }
}

export default {
  id: "baratorama-admin-token",
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
