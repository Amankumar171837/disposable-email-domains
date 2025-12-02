#!/bin/bash
set -e

# Skip git pull in CI environment
if [ -z "$GITHUB_ACTIONS" ]; then
  git pull -q -f
fi

tmpfile=$(mktemp)
# Run basic generation without slow validation flags
# --skip-scrape: Skip domain scraping to speed up execution (use static sources only)
# --max-retry: Reduce retry attempts from 150 to 3 for faster failure handling
./disposable/.generate --skip-scrape --max-retry 3 2>$tmpfile

# Only commit if there are changes
if git diff --quiet domains*.txt domains*.json 2>/dev/null; then
  echo "No changes detected"
  rm "$tmpfile"
  exit 0
fi

git add domains.txt domains.json domains_legacy.txt domains_mx.txt domains_mx.json \
    domains_sha1.json domains_sha1.txt domains_source_map.txt \
    domains_strict.json domains_strict.txt domains_strict_sha1.json domains_strict_sha1.txt \
    domains_strict_source_map.txt domains_strict_mx.json domains_strict_mx.txt

git commit -m "$(printf "Update domains\n\n"; cat $tmpfile)" || echo "No changes to commit"

rm "$tmpfile"

# Push in GitHub Actions
if [ -n "$GITHUB_ACTIONS" ]; then
  git push -q
fi
