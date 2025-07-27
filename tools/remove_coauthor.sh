#!/bin/bash
# Remove all co-authors with emails starting with username@ from git history (using filter-branch + sed)

set -e

echo "WARNING: This will rewrite the entire git history of this repo!"
echo "Make sure you have a backup and coordinate with your team."
read -p "Type 'YES' to continue: " confirm
if [[ "$confirm" != "YES" ]]; then
    echo "Aborted."
    exit 1
fi

git filter-branch --msg-filter '
  sed "/^Co-authored-by:.*<username@.*>\$/d"
' -- --all

echo "Done. All Co-authors with username@... have been removed from commit messages."
echo "You will need to force-push your branches: git push --force --all"
