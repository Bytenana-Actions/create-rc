#!/usr/bin/env bash

configure_git() {
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
}

commit_and_push() {
  local message="$1"
  local branch="$2"
  git add -u
  git commit -m "$message"
  git push origin "$branch"
}
