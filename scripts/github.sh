#!/usr/bin/env bash

create_milestone() {
  local title="$1"
  gh api repos/{owner}/{repo}/milestones \
    --method POST \
    --field title="$title" \
    --jq '.number'
}

create_issue() {
  local title="$1"
  local url
  url=$(gh issue create \
    --title "$title" \
    --body "Tracking issue for ${title}." \
    --milestone "$title")
  echo "${url##*/}"
}

create_branch() {
  local issue_number="$1"
  local base_branch="$2"
  local branch_name="$3"
  gh issue develop "$issue_number" \
    --base "$base_branch" \
    --name "$branch_name" \
    --checkout
}

open_pr() {
  local title="$1"
  local issue_number="$2"
  local base_branch="$3"
  local branch_name="$4"
  gh pr create \
    --title "$title" \
    --body "Closes #${issue_number}" \
    --base "$base_branch" \
    --head "$branch_name"
}
