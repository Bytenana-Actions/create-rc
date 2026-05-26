#!/usr/bin/env bats

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  CALL_LOG="$BATS_TEST_TMPDIR/calls"

  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "issue create"* ]]; then
  echo "https://github.com/owner/repo/issues/42"
elif [[ "\$*" == *"--method POST"* ]]; then
  echo "42"
elif [[ "\$*" == "issue list"* ]]; then
  echo "[]"
elif [[ "\$*" == "pr list"* ]]; then
  echo "[]"
elif [[ "\$*" == "api repos/{owner}/{repo}/branches/"* ]]; then
  exit 1
elif [[ "\$*" == "api repos/{owner}/{repo}/milestones"* ]]; then
  echo "[]"
else
  echo "42"
fi
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

@test "create_milestone returns existing number without creating" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "api repos/{owner}/{repo}/milestones"* && "\$*" != *"--method POST"* ]]; then
  echo '[{"title":"Release Candidate v1.2.0","number":99}]'
else
  echo "0"
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_milestone "Release Candidate v1.2.0"
  [ "$output" = "99" ]
}

@test "create_milestone does not POST when milestone already exists" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "api repos/{owner}/{repo}/milestones"* && "\$*" != *"--method POST"* ]]; then
  echo '[{"title":"Release Candidate v1.2.0","number":99}]'
else
  echo "0"
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_milestone "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"--method POST"* ]]
}

# create_issue

@test "create_issue calls gh issue create" {
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"issue create"* ]]
}

@test "create_issue passes title" {
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"Release Candidate v1.2.0"* ]]
}

@test "create_issue links the milestone by title" {
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--milestone Release Candidate v1.2.0"* ]]
}

@test "create_issue returns the issue number" {
  run create_issue "Release Candidate v1.2.0"
  [ "$output" = "42" ]
}

@test "create_issue returns existing number without creating" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "issue list"* ]]; then
  echo '[{"title":"Release Candidate v1.2.0","number":99}]'
else
  echo "0"
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_issue "Release Candidate v1.2.0"
  [ "$output" = "99" ]
}

@test "create_issue does not call issue create when issue already exists" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "issue list"* ]]; then
  echo '[{"title":"Release Candidate v1.2.0","number":99}]'
else
  echo "0"
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"issue create"* ]]
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

@test "create_branch skips gh issue develop when branch already exists" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "api repos/{owner}/{repo}/branches/"* ]]; then
  echo "{}"
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"
  run create_branch "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"issue develop"* ]]
}

@test "create_branch fetches and checks out branch when it already exists" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "api repos/{owner}/{repo}/branches/"* ]]; then
  echo "{}"
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"
  run create_branch "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"git fetch origin rc-1.2.0"* ]]
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"git checkout rc-1.2.0"* ]]
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

@test "open_pr skips creation when PR already exists" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "pr list"* ]]; then
  echo '[{"number":99}]'
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"pr create"* ]]
}
