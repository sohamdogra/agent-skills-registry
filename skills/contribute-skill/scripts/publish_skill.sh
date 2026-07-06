#!/usr/bin/env bash
# contribute-skill: publish a locally-authored skill to the shared registry as a PR.
#
# Usage:
#   bash publish_skill.sh <path-to-skill-dir>
#
# Reads GITHUB_TOKEN from the environment (or ~/.hermes/registry-publish.env).
# Creates a branch, commits the skill under skills/<name>/, and opens a PR to main.
# It does NOT push to main and does NOT fork — it contributes directly via PR,
# which works when the agent's GitHub identity is a collaborator on the repo.

set -euo pipefail

REPO="sohamdogra/agent-skills-registry"
API="https://api.github.com"

SKILL_DIR="${1:-}"
if [ -z "$SKILL_DIR" ] || [ ! -f "$SKILL_DIR/SKILL.md" ]; then
  echo "ERROR: pass a skill directory containing SKILL.md. Got: '$SKILL_DIR'" >&2
  exit 1
fi

# Load token from durable file if not already in env.
if [ -z "${GITHUB_TOKEN:-}" ] && [ -f "$HOME/.hermes/registry-publish.env" ]; then
  # shellcheck disable=SC1091
  set +u; . "$HOME/.hermes/registry-publish.env"; set -u
fi
if [ -z "${GITHUB_TOKEN:-}" ]; then
  echo "ERROR: no GITHUB_TOKEN. Put it in ~/.hermes/registry-publish.env or export it." >&2
  exit 1
fi

# Derive skill name from the SKILL.md frontmatter (name:) or the folder name.
NAME=$(grep -m1 -E '^name:' "$SKILL_DIR/SKILL.md" | sed -E 's/^name:[[:space:]]*//' | tr -d '"'"'"' \r')
[ -z "$NAME" ] && NAME=$(basename "$SKILL_DIR")
BRANCH="add-skill-$NAME"

auth=(-H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json")

echo "Publishing skill '$NAME' to $REPO as a pull request..."

# 1. base sha of main
BASE_SHA=$(curl -s "${auth[@]}" "$API/repos/$REPO/git/ref/heads/main" | grep -o '"sha": *"[a-f0-9]\{40\}"' | head -1 | grep -o '[a-f0-9]\{40\}')
[ -z "$BASE_SHA" ] && { echo "ERROR: could not read main (token lacks access to $REPO?)" >&2; exit 1; }

# 2. create branch (ignore 'already exists')
curl -s -o /dev/null "${auth[@]}" -X POST "$API/repos/$REPO/git/refs" \
  -d "{\"ref\":\"refs/heads/$BRANCH\",\"sha\":\"$BASE_SHA\"}" || true

# 3. commit every file in the skill dir under skills/<name>/
find "$SKILL_DIR" -type f | while read -r f; do
  rel="${f#"$SKILL_DIR"/}"
  b64=$(base64 -w0 "$f")
  # look up existing file sha on the branch (for updates)
  existing=$(curl -s "${auth[@]}" "$API/repos/$REPO/contents/skills/$NAME/$rel?ref=$BRANCH" | grep -o '"sha": *"[a-f0-9]\{40\}"' | head -1 | grep -o '[a-f0-9]\{40\}' || true)
  shaline=""
  [ -n "$existing" ] && shaline=",\"sha\":\"$existing\""
  curl -s -o /dev/null "${auth[@]}" -X PUT "$API/repos/$REPO/contents/skills/$NAME/$rel" \
    -d "{\"message\":\"Add $NAME skill: $rel\",\"content\":\"$b64\",\"branch\":\"$BRANCH\"$shaline}"
  echo "  committed skills/$NAME/$rel"
done

# 4. open the PR (capture the URL)
PR=$(curl -s "${auth[@]}" -X POST "$API/repos/$REPO/pulls" \
  -d "{\"title\":\"Add $NAME skill (authored by an agent)\",\"head\":\"$BRANCH\",\"base\":\"main\",\"body\":\"This skill was authored on an agent's VM and contributed to the shared registry via the contribute-skill playbook. A maintainer reviews and merges; on merge every agent can install it.\"}")

URL=$(echo "$PR" | grep -o '"html_url": *"[^"]*/pull/[0-9]*"' | head -1 | sed -E 's/.*"(https[^"]*)"/\1/')
if [ -n "$URL" ]; then
  echo "PR opened: $URL"
else
  # a PR may already exist for this branch
  echo "Note: PR may already exist for branch $BRANCH. API said:"
  echo "$PR" | grep -o '"message": *"[^"]*"' | head -1
fi
