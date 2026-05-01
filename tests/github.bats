#!/usr/bin/env bats

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  CALL_LOG="$BATS_TEST_TMPDIR/calls"

  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
echo "42"
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"

  source "${BATS_TEST_DIRNAME}/../scripts/github.sh"
}

# create_milestone

@test "create_milestone calls gh api milestones endpoint" {
  run create_milestone "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"api repos/{owner}/{repo}/milestones"* ]]
}

@test "create_milestone passes title as a field" {
  run create_milestone "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"Release Candidate v1.2.0"* ]]
}

@test "create_milestone returns the milestone number" {
  run create_milestone "Release Candidate v1.2.0"
  [ "$output" = "42" ]
}

# create_issue

@test "create_issue calls gh issue create" {
  run create_issue "Release Candidate v1.2.0" "5"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"issue create"* ]]
}

@test "create_issue passes title" {
  run create_issue "Release Candidate v1.2.0" "5"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"Release Candidate v1.2.0"* ]]
}

@test "create_issue links the milestone" {
  run create_issue "Release Candidate v1.2.0" "5"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--milestone 5"* ]]
}

@test "create_issue returns the issue number" {
  run create_issue "Release Candidate v1.2.0" "5"
  [ "$output" = "42" ]
}

# create_branch

@test "create_branch calls gh issue develop" {
  run create_branch "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"issue develop 42"* ]]
}

@test "create_branch sets the correct base branch" {
  run create_branch "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--base master"* ]]
}

@test "create_branch sets the correct branch name" {
  run create_branch "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--name rc-1.2.0"* ]]
}

# open_pr

@test "open_pr calls gh pr create" {
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"pr create"* ]]
}

@test "open_pr sets the correct title" {
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"Release Candidate v1.2.0"* ]]
}

@test "open_pr body closes the tracking issue" {
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"Closes #42"* ]]
}

@test "open_pr targets the correct base branch" {
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--base master"* ]]
}

@test "open_pr uses the rc branch as head" {
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--head rc-1.2.0"* ]]
}
