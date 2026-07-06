// ──────────────────────────────────────────────────────────────────────────
// Ghost ⇄ iMessage bridge  (portable)
// Connects a Hermes (Ghost) agent to iMessage via Photon/Spectrum.
//
// To use: drop your PROJECT_ID and PROJECT_SECRET into .env, then `npm start`.
// Nothing else in this file needs editing — it works for any Hermes agent VM.
//
// How it works:
//   incoming iMessage ─▶ Spectrum ─▶ `hermes chat` on this VM ─▶ reply ─▶ iMessage
//   Each iMessage conversation gets its own Hermes session (persistent memory):
//     • first message  → create session, capture the printed session_id
//     • later messages → --resume <session_id>
//   The map is saved to sessions.json so memory survives restarts.
// ──────────────────────────────────────────────────────────────────────────

import { Spectrum } from "spectrum-ts";
import { imessage } from "spectrum-ts/providers/imessage";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const run = promisify(execFile);
const HERE = import.meta.dirname;

// ── tiny .env loader (so `node index.mjs` works without extra flags) ──────────
const envPath = join(HERE, ".env");
if (existsSync(envPath)) {
  for (const line of readFileSync(envPath, "utf8").split("\n")) {
    const m = line.match(/^\s*([A-Za-z0-9_]+)\s*=\s*(.*?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, "");
  }
}

const PROJECT_ID = process.env.PROJECT_ID;
const PROJECT_SECRET = process.env.PROJECT_SECRET;
const HERMES_BIN = process.env.HERMES_BIN || "hermes";
const HERMES_MODEL = process.env.HERMES_MODEL || ""; // optional override
// Run the agent from a neutral home dir (NOT this kit folder), so Hermes uses
// its normal persona/memory instead of treating this repo as the task context.
const AGENT_CWD = process.env.AGENT_CWD || process.env.HOME || "/root";

if (!PROJECT_ID || !PROJECT_SECRET) {
  console.error("ERROR: PROJECT_ID and PROJECT_SECRET must be set (in .env or the environment).");
  console.error("Get them from your project at https://app.photon.codes");
  process.exit(1);
}

const SESS_FILE = join(HERE, "sessions.json");
const loadSessions = () => { try { return JSON.parse(readFileSync(SESS_FILE, "utf8")); } catch { return {}; } };
const saveSessions = (m) => { try { writeFileSync(SESS_FILE, JSON.stringify(m, null, 2)); } catch (e) { console.error("[sess] save failed:", e.message); } };
let sessions = loadSessions();

const spaceKey = (space) => String(space?.id ?? "default");
const parseSessionId = (s) => (s || "").match(/session_id:\s*(\S+)/)?.[1] ?? null;
const cleanReply = (out) =>
  (out || "").split("\n").filter((l) => !/^\s*session_id:/i.test(l)).join("\n").trim();

async function askAgent(text, space, allowRetry = true) {
  const key = spaceKey(space);
  const existing = sessions[key];
  const args = ["chat", "-q", text, "-Q", "--yolo", "--source", "tool"];
  if (HERMES_MODEL) args.push("-m", HERMES_MODEL);
  if (existing) args.push("--resume", existing);

  let res;
  try {
    res = await run(HERMES_BIN, args, { cwd: AGENT_CWD, timeout: 180000, maxBuffer: 16 * 1024 * 1024 });
  } catch (e) {
    if (existing && allowRetry) {            // stale session → start fresh once
      console.error("[sess] resume failed, starting fresh:", e.message);
      delete sessions[key]; saveSessions(sessions);
      return askAgent(text, space, false);
    }
    throw e;
  }

  const id = parseSessionId(res.stderr);
  if (id && id !== existing) { sessions[key] = id; saveSessions(sessions); }
  return cleanReply(res.stdout) || "(the agent returned an empty reply)";
}

const app = await Spectrum({
  projectId: PROJECT_ID,
  projectSecret: PROJECT_SECRET,
  providers: [imessage.config()],
});

console.log(`[bridge] up. agent='${HERMES_BIN}'${HERMES_MODEL ? ` model='${HERMES_MODEL}'` : ""} cwd='${AGENT_CWD}'. waiting for messages...`);

for await (const [space, message] of app.messages) {
  if (message?.content?.type !== "text") continue;
  const incoming = message.content.text;
  console.log("[IN ]", spaceKey(space), "=>", incoming);
  try {
    const reply = await askAgent(incoming, space);
    console.log("[OUT]", reply.slice(0, 200));
    await space.send(reply);
  } catch (err) {
    console.error("[ERR]", err?.message || err);
    await space.send("⚠️ Ghost agent error: " + (err?.message || "unknown"));
  }
}
