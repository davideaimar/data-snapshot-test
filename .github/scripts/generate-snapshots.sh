#!/bin/bash
set -euo pipefail

# Create output directory
mkdir -p data
mkdir -p data/commits

echo "🔍 Discovering all branches..."
# Get all remote branches (excluding HEAD and main)
branches=$(git branch -r | grep -v '\->' | sed 's/origin\///' | grep -vE 'main|master|develop' | sort -u)

volumes_json="{"
first_volume=true

for branch in $branches; do
echo "📂 Processing branch: $branch"

# Skip if branch doesn't exist or is HEAD
if [[ "$branch" == "HEAD" ]] || ! git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    echo "⚠️  Skipping invalid branch: $branch"
    continue
fi

# Checkout branch
git checkout "$branch" 2>/dev/null || {
    echo "⚠️  Could not checkout branch: $branch"
    continue
}

# Get all commits for this branch (reverse chronological order)
commits=$(git log --format="%H|%ai|%s" --reverse)

if [ -z "$commits" ]; then
    echo "⚠️  No commits found in branch: $branch"
    continue
fi

# Add comma separator for JSON
if [ "$first_volume" = false ]; then
    volumes_json="$volumes_json,"
fi
first_volume=false

# Start volume JSON (no files)
volumes_json="$volumes_json\"$branch\":{\"commits\":["

first_commit=true
commit_count=0

while IFS='|' read -r commit_hash commit_date commit_message; do
    # Skip empty lines
    [ -z "$commit_hash" ] && continue
    
    echo "  📝 Processing commit: $commit_hash ($(echo "$commit_message" | head -c 50)...)"
    
    # Checkout specific commit
    git checkout "$commit_hash" 2>/dev/null || {
    echo "    ⚠️  Could not checkout commit: $commit_hash"
    continue
    }
    
    # Add comma separator for JSON
    if [ "$first_commit" = false ]; then
    volumes_json="$volumes_json,"
    fi
    first_commit=false
    
    # Parse all .meta files in this commit
    files_json=""
    first_file=true
    total_size=0
    file_count=0
    
    # Find all .meta files
    while IFS= read -r -d '' metafile; do
    if [ -f "$metafile" ]; then
        # Extract path without .meta extension
        original_path="${metafile%.meta}"
        
        # Read and validate JSON
        if jq empty "$metafile" 2>/dev/null; then
        # Add comma separator
        if [ "$first_file" = false ]; then
            files_json="$files_json,"
        fi
        first_file=false
        
        # Extract metadata using jq
        path=$(jq -r '.path' "$metafile" 2>/dev/null || echo "unknown")
        size=$(jq -r '.size' "$metafile" 2>/dev/null || echo "0")
        sha256=$(jq -r '.sha256' "$metafile" 2>/dev/null || echo "unknown")
        
        # Escape path for JSON
        path_escaped=$(echo "$path" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
        
        # Add to files JSON
        files_json="$files_json\"$path_escaped\":{\"size\":$size,\"sha256\":\"$sha256\"}"
        
        # Update stats
        total_size=$((total_size + size))
        file_count=$((file_count + 1))
        else
        echo "    ⚠️  Invalid JSON in: $metafile"
        fi
    fi
    done < <(find . -name "*.meta" -type f -print0)
    
    # Create commit JSON
    commit_date_escaped=$(echo "$commit_date" | sed 's/"/\\"/g')
    commit_message_escaped=$(echo "$commit_message" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g')
    
    volumes_json="$volumes_json{\"hash\":\"$commit_hash\",\"date\":\"$commit_date_escaped\",\"message\":\"$commit_message_escaped\",\"stats\":{\"file_count\":$file_count,\"total_size\":$total_size}}"
    
    commit_detail="{\"hash\":\"$commit_hash\",\"date\":\"$commit_date_escaped\",\"message\":\"$commit_message_escaped\",\"volume\":\"$branch\",\"stats\":{\"file_count\":$file_count,\"total_size\":$total_size},\"files\":{$files_json}}"
    echo "$commit_detail" | jq '.' > "data/commits/$commit_hash.json"
    
    commit_count=$((commit_count + 1))
    echo "    ✅ Processed $file_count files ($(numfmt --to=iec $total_size))"
    
done <<< "$commits"

# Close commits array for this volume
volumes_json="$volumes_json]}"

echo "✅ Branch '$branch' complete: $commit_count commits processed"
done

# Close volumes JSON
volumes_json="$volumes_json}"

# Create volumes list JSON
volumes_list_json="{\"generated_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"volumes\":$volumes_json}"

echo "💾 Writing API JSON files..."
echo "$volumes_list_json" | jq '.' > data/volumes.json

# Create summary stats
echo "📊 Generating summary..."
echo "$volumes_list_json" | jq '{
generated_at: .generated_at,
summary: {
    total_volumes: (.volumes | length),
    total_commits: (.volumes | to_entries | map(.value.commits | length) | add),
    volume_stats: (.volumes | to_entries | map({
    name: .key,
    commits: (.value.commits | length),
    latest_date: (.value.commits | map(.date) | max),
    total_files: (.value.commits | map(.stats.file_count) | max),
    total_size: (.value.commits | map(.stats.total_size) | max)
    }))
}
}' > data/summary.json

echo "✅ API generation complete!"

# Print summary
echo ""
echo "📋 SUMMARY:"
cat data/summary.json | jq -r '.summary.volume_stats[] | "  📂 \(.name): \(.commits) commits, \(.total_files) files, \(.total_size / 1024 / 1024 | floor)MB"'
echo ""
echo "📁 Generated APIs:"
echo "    • summary.json - Overview stats"
echo "    • volumes.json - Volumes + commits (no files)"
echo "    • commits/{hash}.json - Individual commit details"

# Create a simple index.html placeholder
cat > data/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
<title>Volume Snapshots APIs</title>
<meta charset="utf-8">
</head>
<body>
<h1>Volume Snapshots APIs</h1>
<h2>API Endpoints:</h2>
<ul>
    <li><a href="../data/summary.json">summary.json</a> - Overview and stats</li>
    <li><a href="../data/volumes.json">volumes.json</a> - Volumes and commits (lightweight)</li>
    <li><strong>commits/{hash}.json</strong> - Individual commit details with files</li>
</ul>
<h2>Usage:</h2>
<pre>
# Get overview
GET /data/summary.json

# List volumes and commits  
GET /data/volumes.json

# Get specific commit details
GET /data/commits/{commit-hash}.json
</pre>
<p><em>Web interface coming soon...</em></p>
</body>
</html>
EOF