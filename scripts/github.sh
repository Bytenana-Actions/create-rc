#!/usr/bin/env bash

create_milestone() {
  local title="$1"
  local number
  if number=$(gh api repos/{owner}/{repo}/milestones \
    --method POST \
    --field title="$title" \
    --jq '.number' 2>/dev/null); then
    echo "$number"
    return
  fi
  gh api "repos/{owner}/{repo}/milestones?state=all" --paginate \
    | jq -rs --arg t "$title" '.[][] | select(.title == $t) | .number'
}

create_issue() {
  local title="$1"
  local existing
  existing=$(gh issue list \
    --state all \
    --limit 500 \
    --json number,title \
    | jq -r --arg t "$title" '.[] | select(.title == $t) | .number' \
    | head -1)
  if [ -n "$existing" ]; then
    echo "$existing"
    return
  fi
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
  if gh issue develop "$issue_number" \
    --base "$base_branch" \
    --name "$branch_name" \
    --checkout 2>/dev/null; then
    return
  fi
  git fetch origin "$branch_name"
  git checkout "$branch_name"
}

open_pr() {
  local title="$1"
  local issue_number="$2"
  local base_branch="$3"
  local branch_name="$4"
  local existing
  existing=$(gh pr list \
    --head "$branch_name" \
    --base "$base_branch" \
    --state open \
    --json number \
    | jq -r '.[0].number // empty')
  if [ -n "$existing" ]; then
    return
  fi
  gh pr create \
    --title "$title" \
    --body "Closes #${issue_number}" \
    --base "$base_branch" \
    --head "$branch_name"
}
