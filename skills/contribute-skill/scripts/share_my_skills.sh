#!/usr/bin/env bash
# share-my-skills: contribute this agent's genuinely-new skills to the shared registry.
#
# For each local skill, it SKIPS:
#   - skills already present in the registry (dedup by name)
#   - a denylist of built-in / default runtime skills
#   - any skill folder that contains a secret (.env, token, key, session file)
# and auto-contributes the rest, each as its own PR (via publish_skill.sh).
#
# Usage:
#   bash share_my_skills.sh [skills_dir]     # default: ~/.hermes/skills
#
# Requires GITHUB_TOKEN (Contents+PR write) — loaded from ~/.hermes/registry-publish.env.

set -uo pipefail

REPO="sohamdogra/agent-skills-registry"
API="https://api.github.com"
SKILLS_DIR="${1:-$HOME/.hermes/skills}"
HERE="$(cd "$(dirname "$0")" && pwd)"
PUBLISH="$HERE/publish_skill.sh"

# Built-in / default runtime skills that every agent already has — never contribute these.
DENYLIST="agent-browser google-via-browser browser-automation feishu-doc feishu-drive feishu-perm feishu-wiki contribute-skill share-my-skills registry-smoke-test"

# Load token.
if [ -z "${GITHUB_TOKEN:-}" ] && [ -f "$HOME/.hermes/registry-publish.env" ]; then
  set +u; . "$HOME/.hermes/registry-publish.env"; set -u
fi
[ -z "${GITHUB_TOKEN:-}" ] && { echo "ERROR: no GITHUB_TOKEN (see ~/.hermes/registry-publish.env)"; exit 1; }
auth=(-H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")

contributed=(); skipped_dup=(); skipped_builtin=(); skipped_secret=(); skipped_nomd=()

for dir in "$SKILLS_DIR"/*/; do
  name="$(basename "$dir")"
  [ -f "$dir/SKILL.md" ] || { skipped_nomd+=("$name"); continue; }

  # 1. denylist (built-ins / registry-tooling)
  if echo " $DENYLIST " | grep -q " $name "; then skipped_builtin+=("$name"); continue; fi

  # 2. secret scan — refuse to contribute a skill folder holding credentials
  if find "$dir" -type f \( -name '.env' -o -name '*.pem' -o -name '*.key' -o -name '*session*.json' -o -name 'cookies.json' \) 2>/dev/null | grep -q .; then
    skipped_secret+=("$name"); continue
  fi
  if grep -rIlE '(GITHUB_TOKEN|PROJECT_SECRET|api[_-]?key|secret)[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_-]{16,}' "$dir" 2>/dev/null | grep -q .; then
    skipped_secret+=("$name"); continue
  fi

  # 3. dedup — already in the registry?
  code=$(curl -s -o /dev/null -w '%{http_code}' "${auth[@]}" "$API/repos/$REPO/contents/skills/$name/SKILL.md?ref=main")
  if [ "$code" = "200" ]; then skipped_dup+=("$name"); continue; fi

  # 4. contribute it
  echo ">>> contributing new skill: $name"
  if bash "$PUBLISH" "$dir" 2>&1 | sed 's/^/    /'; then
    contributed+=("$name")
  fi
done

echo
echo "===== share-my-skills summary ====="
echo "Contributed (new PRs):   ${contributed[*]:-none}"
echo "Skipped — already in reg: ${skipped_dup[*]:-none}"
echo "Skipped — built-in/tool:  ${skipped_builtin[*]:-none}"
echo "Skipped — has secrets:    ${skipped_secret[*]:-none}"
echo "Skipped — no SKILL.md:    ${skipped_nomd[*]:-none}"
