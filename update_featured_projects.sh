#!/usr/bin/env bash
# Auto-updates the "Featured Projects" section of README.md with the
# 3 most recently pushed-to repos (forks excluded), newest first.
set -euo pipefail

USERNAME="kinjalss"
README="README.md"
START_MARKER="<!-- FEATURED-PROJECTS:START -->"
END_MARKER="<!-- FEATURED-PROJECTS:END -->"

# Fetch repos sorted by last push, non-forks only, top 3
REPOS=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
  "https://api.github.com/users/${USERNAME}/repos?sort=pushed&direction=desc&per_page=30" \
  | jq -r '[.[] | select(.fork == false)] | sort_by(.pushed_at) | reverse | .[0:3] | .[].name')

if [ -z "$REPOS" ]; then
  echo "No repos found or API error — leaving README unchanged."
  exit 0
fi

# Build the new markdown block
BLOCK="<div align=\"center\">\n\n"
while IFS= read -r repo; do
  BLOCK+="<a href=\"https://github.com/${USERNAME}/${repo}\" target=\"_blank\">\n"
  BLOCK+="  <img src=\"https://github-stats-extended.vercel.app/api/pin/?username=${USERNAME}&repo=${repo}&theme=radical&hide_border=true&bg_color=0D1117&title_color=EC4899&icon_color=6366F1&text_color=FFFFFF\" />\n"
  BLOCK+="</a>\n"
done <<< "$REPOS"
BLOCK+="\n</div>"

# Replace everything between the markers
awk -v start="$START_MARKER" -v end="$END_MARKER" -v block="$BLOCK" '
  $0 ~ start { print; print block; skip=1; next }
  $0 ~ end   { print; skip=0; next }
  !skip { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

echo "Featured Projects updated with: $REPOS"
