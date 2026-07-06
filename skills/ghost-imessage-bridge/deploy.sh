#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════════
#  Ghost ⇄ iMessage — easy setup (one file)
#
#  Run it, sign in when a link pops up, paste your 2 Photon keys. Done.
#  It installs anything it needs, finds your Hermes agent for you, and starts
#  the bridge so your agent can text on iMessage (via Photon — no Mac needed).
#
#  HOW TO RUN:
#    Mac / Linux : open Terminal, then:   bash deploy.sh
#    Windows     : open "Ubuntu" (WSL), then:   bash deploy.sh
#
#  The only thing you need first: your 2 keys from https://app.photon.codes
#  (create a project → pick iMessage → add your phone → copy PROJECT_ID + SECRET)
# ════════════════════════════════════════════════════════════════════════════
set -euo pipefail

echo "============================================"
echo "  Ghost  iMessage  —  easy setup"
echo "============================================"
echo

# ── 1. Install the inference.ai CLI if it isn't here yet ────────────────────
if ! command -v inferenceai >/dev/null 2>&1 && [ ! -x "$HOME/.local/bin/inferenceai" ]; then
  echo "→ One-time setup: installing the inference.ai app..."
  mkdir -p "$HOME/.local/bin"
  curl -fsSL agents.inference.ai/cli | INFERENCEAI_INSTALL_DIR="$HOME/.local/bin" sh
fi
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
IAI="$(command -v inferenceai || echo "$HOME/.local/bin/inferenceai")"
[ -x "$IAI" ] || { echo "Could not install the CLI automatically. See https://agents.inference.ai"; exit 1; }

# ── 2. Sign in if needed ────────────────────────────────────────────────────
if ! "$IAI" whoami >/dev/null 2>&1; then
  echo "→ Let's sign you in. A link will appear — open it and click Approve."
  "$IAI" login
fi
echo "✓ Signed in."

# ── 3. Find your Hermes agent automatically ─────────────────────────────────
echo "→ Looking for your Hermes agent..."
VMS="$("$IAI" list 2>/dev/null | grep -i hermes | grep -oE 'vm-[a-z0-9]+' | sort -u || true)"
COUNT="$(printf '%s\n' "$VMS" | grep -c . || true)"
if [ "$COUNT" -eq 0 ]; then
  echo "✗ Couldn't find a Hermes agent on your account."
  echo "  This bridge needs a Ghost agent running the Hermes runtime."
  exit 1
elif [ "$COUNT" -eq 1 ]; then
  VM="$VMS"
  echo "✓ Found it: $VM"
else
  echo "  You have more than one Hermes agent:"
  printf '%s\n' "$VMS" | nl
  read -rp "  Which one? (paste the vm-... name): " VM
fi

# ── 4. Ask only for the 2 Photon keys ───────────────────────────────────────
echo
echo "Paste your 2 keys from https://app.photon.codes (your project → iMessage)."
echo "Don't have them? Open that link, create a project, pick iMessage, add your"
echo "phone, and copy the two values. Then come back here."
echo
read -rp "PROJECT_ID:      " PID
read -rp "PROJECT_SECRET:  " SECRET
[ -n "$PID" ] && [ -n "$SECRET" ] || { echo "✗ Both keys are required."; exit 1; }

# ── 5. Write the bridge files to a temp folder ──────────────────────────────
WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

cat > "$WORK/index.mjs" <<'INDEX_EOF'
import { Spectrum } from "spectrum-ts";
import { imessage } from "spectrum-ts/providers/imessage";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { join } from "node:path";

const run = promisify(execFile);
const HERE = import.meta.dirname;

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
const HERMES_MODEL = process.env.HERMES_MODEL || "";
// Run the agent from a neutral home dir (NOT this kit folder) so Hermes uses
// its normal persona/memory instead of treating this repo as the task context.
const AGENT_CWD = process.env.AGENT_CWD || process.env.HOME || "/root";

if (!PROJECT_ID || !PROJECT_SECRET) {
  console.error("ERROR: PROJECT_ID and PROJECT_SECRET must be set (in .env or env).");
  process.exit(1);
}

const SESS_FILE = join(HERE, "sessions.json");
const loadSessions = () => { try { return JSON.parse(readFileSync(SESS_FILE, "utf8")); } catch { return {}; } };
const saveSessions = (m) => { try { writeFileSync(SESS_FILE, JSON.stringify(m, null, 2)); } catch (e) { console.error("[sess] save failed:", e.message); } };
let sessions = loadSessions();

const spaceKey = (space) => String(space?.id ?? "default");
const parseSessionId = (s) => (s || "").match(/session_id:\s*(\S+)/)?.[1] ?? null;
const cleanReply = (out) => (out || "").split("\n").filter((l) => !/^\s*session_id:/i.test(l)).join("\n").trim();

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
    if (existing && allowRetry) {
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
INDEX_EOF

cat > "$WORK/package.json" <<'PKG_EOF'
{
  "name": "ghost-imessage-bridge",
  "version": "1.0.0",
  "private": true,
  "type": "module",
  "scripts": { "start": "node index.mjs", "stop": "pkill -f index.mjs || true" },
  "dependencies": { "spectrum-ts": "^7.0.0" }
}
PKG_EOF

cat > "$WORK/setup.sh" <<'SETUP_EOF'
#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ "${1:-}" != "" ] && [ "${2:-}" != "" ]; then
  printf 'PROJECT_ID=%s\nPROJECT_SECRET=%s\n' "$1" "$2" > .env
fi
[ -f .env ] || { echo "no .env"; exit 1; }
command -v hermes >/dev/null || { echo "'hermes' not on PATH — run on a Ghost Hermes VM"; exit 1; }
npm install --no-fund --no-audit

# Stop any old bridge or supervisor.
pkill -f "run.sh" 2>/dev/null || true
pkill -f "index.mjs" 2>/dev/null || true
sleep 1
: > bridge.log

# Supervisor: keep the bridge alive across crashes / Photon stream drops.
cat > run.sh <<'RUN_EOF'
#!/usr/bin/env bash
cd "$(dirname "$0")"
export AGENT_CWD="${AGENT_CWD:-/root}"
while true; do
  echo "[supervisor] starting bridge $(date -u +%FT%TZ)" >> bridge.log
  node index.mjs >> bridge.log 2>&1 || true
  echo "[supervisor] bridge exited; restarting in 5s $(date -u +%FT%TZ)" >> bridge.log
  sleep 5
done
RUN_EOF
chmod +x run.sh

# Launch the supervisor, fully detached so it survives the SSH session.
setsid bash run.sh < /dev/null >/dev/null 2>&1 &
sleep 6
cat bridge.log
SETUP_EOF

cat > "$WORK/stop.sh" <<'STOP_EOF'
#!/usr/bin/env bash
# Kill the supervisor first so it doesn't relaunch the bridge, then the bridge.
pkill -f "run.sh" 2>/dev/null || true
pkill -f "index.mjs" 2>/dev/null && echo "stopped" || echo "(not running)"
STOP_EOF

# ── 6. Send it to your agent and start it ───────────────────────────────────
echo
echo "→ Setting up your agent (about 30 seconds)..."
"$IAI" exec --vm "$VM" mkdir -p /root/ghost-imessage-kit
for f in index.mjs package.json setup.sh stop.sh; do
  "$IAI" cp "$WORK/$f" ":/root/ghost-imessage-kit/$f" --vm "$VM" >/dev/null
done
"$IAI" exec --vm "$VM" bash /root/ghost-imessage-kit/setup.sh "$PID" "$SECRET" >/dev/null

echo
echo "============================================"
echo "  ✓ Done!  Your agent is now on iMessage."
echo "============================================"
echo "  Text your Photon line (from app.photon.codes) from the phone you added,"
echo "  and your agent will reply. First reply can take a few seconds."
echo
echo "  Stop it later:  bash deploy.sh   is not needed — to stop, run:"
echo "    $IAI exec --vm $VM bash /root/ghost-imessage-kit/stop.sh"
