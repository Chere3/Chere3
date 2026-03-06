#!/usr/bin/env bash
set -euo pipefail

README_PATH="${1:-README.md}"
if [[ ! -f "$README_PATH" ]]; then
  echo "README not found: $README_PATH" >&2
  exit 1
fi

mapfile -t URLS < <(grep -Eo 'https?://[^) >]+' "$README_PATH" | sort -u)
if [[ ${#URLS[@]} -eq 0 ]]; then
  echo "No URLs found in $README_PATH"
  exit 0
fi

failed=0
for url in "${URLS[@]}"; do
  code=$(curl -L -s -o /dev/null -w '%{http_code}' --max-time 15 "$url" || echo "000")
  if [[ "$code" =~ ^2|3 ]]; then
    echo "✅ $code $url"
  elif [[ "$url" == *"linkedin.com"* && "$code" == "999" ]]; then
    echo "⚠️  $code $url (treated as pass: LinkedIn bot protection)"
    echo "✅ $code $url"
  else
    echo "❌ $code $url"
    failed=1
  fi
done

if [[ $failed -ne 0 ]]; then
  echo "One or more profile links failed validation."
  exit 1
fi

echo "All profile links are healthy."
