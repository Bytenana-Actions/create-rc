#!/usr/bin/env bash

configure_git() {
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
}

commit_and_push() {
  local message="$1"
  local branch="$2"
  git add -u
  if git diff --cached --quiet; then
    echo "::error::bump-command ran but no tracked files were modified." \
         "The file your bump-command writes to must already exist and be committed in this repository." \
         "See https://github.com/Bytenana-Actions/create-rc/blob/master/docs/create-rc.md for examples."
    exit 1
  fi
  git commit -m "$message"
  git push origin "$branch"
}
