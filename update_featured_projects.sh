#!/usr/bin/env bash
# Auto-updates the "Featured Projects" section of README.md with the
# 3 most recently pushed-to repos (forks excluded), newest first.
set -euo pipefail

USERNAME="kinjalss"
README="README.md"
START_MARKER="<!-- FEATURED-PROJECTS:START -->"
END_MARKER="<!-- FEATURED-PROJECTS:END -->"

if [ ! -f "$README" ]; then
  echo "ERROR: $README not found in repo root. Aborting."
  exit 1
fi

echo "Fetching repos for $USERNAME..."
REPOS=$(curl -s -H "Authorization: token ${GH_TOKEN}" \
  "https://api.github.com/users/${USERNAME}/repos?sort=pushed&direction=desc&per_page=30" \
  | jq -r '[.[] | select(.fork == false)] | sort_by(.pushed_at) | reverse | .[0:3] | .[].name')

if [ -z "$REPOS" ]; then
  echo "No repos found or API error - leaving README unchanged."
  exit 0
fi

echo "Top repos found:"
echo "$REPOS"

# Build the new markdown block with real newlines (not literal \n)
{
  echo '<div align="center">'
  echo ""
  while IFS= read -r repo; do
    echo "<a href=\"https://github.com/${USERNAME}/${repo}\" target=\"_blank\">"
    echo "  <img src=\"https://github-stats-extended.vercel.app/api/pin/?username=${USERNAME}&repo=${repo}&theme=radical&hide_border=true&bg_color=0D1117&title_color=EC4899&icon_color=6366F1&text_color=FFFFFF\" />"
    echo "</a>"
  done <<< "$REPOS"
  echo ""
  echo "</div>"
} > /tmp/featured_block.txt

# Replace everything between the markers using the block file (avoids awk -v escaping issues)
awk -v start="$START_MARKER" -v end="$END_MARKER" '
  $0 ~ start { print; while ((getline line < "/tmp/featured_block.txt") > 0) print line; skip=1; next }
  $0 ~ end   { print; skip=0; next }
  !skip { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

echo "README.md updated successfully."
