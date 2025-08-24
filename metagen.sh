#!/usr/bin/env bash
set -euo pipefail

REPO="git@github.com:davideaimar/data-snapshot-test.git"

# detect hash command
if command -v sha256sum >/dev/null 2>&1; then
  hashcmd="sha256sum --"
elif command -v shasum >/dev/null 2>&1; then
  hashcmd="shasum -a 256 --"
elif command -v openssl >/dev/null 2>&1; then
  hashcmd="openssl dgst -sha256"
else
  echo "Error: need sha256sum or shasum or openssl installed." >&2
  exit 2
fi

stat_size() {
  if stat --version >/dev/null 2>&1; then
    stat -c %s -- "$1"
  else
    stat -f %z -- "$1"
  fi
}

read -r -p "Folder logical name <volume>: " VOLUME
if [ -z "$VOLUME" ]; then
  echo "No volume name provided. Exiting." >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is required." >&2
  exit 2
fi

CURDIR="$(pwd)"

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

echo "Cloning repo..."
git clone --depth 1 "$REPO" "$tmpdir" >/dev/null 2>&1 || {
  echo "Full clone fallback..."
  git clone "$REPO" "$tmpdir"
}

cd "$tmpdir"
git checkout -B "$VOLUME"

# --- WIPE existing branch content except .git ---
shopt -s dotglob  # include hidden files
for f in *; do
  if [ "$f" != ".git" ]; then
    rm -rf -- "$f"
  fi
done
shopt -u dotglob

echo "Creating .meta files inside temp directory..."

script_name="$(basename "${BASH_SOURCE[0]}")"

while IFS= read -r -d '' file; do
  basefile="$(basename "$file")"

  case "$file" in
    *.meta) continue ;;
    *.DS_Store|.DS_Store|Thumbs.db|._*) continue ;;
  esac

  if [ "$basefile" = "$script_name" ]; then
    # Skip the script itself
    continue
  fi

  rel="${file#"$CURDIR"/}"

  size="$(stat_size "$file")"

  if [[ "$hashcmd" == "openssl dgst -sha256" ]]; then
    sig="$(openssl dgst -sha256 "$file" | awk '{print $2}')"
  else
    sig="$($hashcmd "$file" | awk '{print $1}')"
  fi

  metafile="$tmpdir/$rel.meta"
  mkdir -p "$(dirname "$metafile")"
  cat > "$metafile" <<EOF
{
  "path": "$rel",
  "size": $size,
  "sha256": "$sig"
}
EOF

done < <(find "$CURDIR" -type f -print0)

git add .

if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Snapshot of $VOLUME at $(date -u +%Y-%m-%dT%H:%M)"
fi

echo "Pushing to origin/$VOLUME (force update)..."
git push -u origin "$VOLUME" --force

echo "Done. Branch pushed: $VOLUME"
