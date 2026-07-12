#!/usr/bin/env bash
# Encrypts every secret-*.yaml under this repo that isn't already encrypted.
# Safe to run repeatedly — already-encrypted files are skipped, not double-encrypted.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"

if ! command -v sops &> /dev/null; then
  echo "Error: sops is not installed or not on PATH."
  exit 1
fi

FILES=$(find . -path ./node_modules -prune -o -type f -name 'secret-*.yaml' -print)

if [ -z "$FILES" ]; then
  echo "No secret-*.yaml files found."
  exit 0
fi

ENCRYPTED_COUNT=0
SKIPPED_COUNT=0

for f in $FILES; do
  if grep -q "^sops:" "$f" 2>/dev/null; then
    echo "  already encrypted, skipping: $f"
    SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    continue
  fi

  echo "  encrypting: $f"
  sops --encrypt --in-place "$f"
  ENCRYPTED_COUNT=$((ENCRYPTED_COUNT + 1))
done

echo ""
echo "Done. Encrypted: $ENCRYPTED_COUNT, already encrypted: $SKIPPED_COUNT"

echo ""
echo "Sanity check — confirming no plaintext secret-*.yaml remain:"
UNENCRYPTED=""
for f in $FILES; do
  if ! grep -q "^sops:" "$f" 2>/dev/null; then
    UNENCRYPTED="$UNENCRYPTED $f"
  fi
done

if [ -n "$UNENCRYPTED" ]; then
  echo "  WARNING: these files are still NOT encrypted:"
  for f in $UNENCRYPTED; do
    echo "    - $f"
  done
  exit 1
else
  echo "  All secret-*.yaml files are encrypted. Safe to commit."
fi