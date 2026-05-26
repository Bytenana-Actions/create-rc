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

@test "create_milestone returns existing number when creation fails" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == *"--method POST"* ]]; then
  echo "gh: Validation Failed (HTTP 422)" >&2
  exit 1
elif [[ "\$*" == "api repos/{owner}/{repo}/milestones"* ]]; then
  echo '[{"title":"Release Candidate v1.2.0","number":99}]'
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_milestone "Release Candidate v1.2.0"
  [ "$output" = "99" ]
}

# regression: -F state=all caused gh to POST instead of GET — must be query param
@test "create_milestone fallback uses ?state=all in URL not -F flag" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == *"--method POST"* ]]; then
  exit 1
fi
echo "[]"
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_milestone "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"?state=all"* ]]
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"-F state=all"* ]]
}

@test "create_milestone fallback uses --paginate" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == *"--method POST"* ]]; then
  exit 1
fi
echo "[]"
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_milestone "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--paginate"* ]]
}

@test "create_milestone fallback finds match across multiple pages" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == *"--method POST"* ]]; then
  exit 1
fi
echo '[{"title":"Other","number":1}]'
echo '[{"title":"Release Candidate v1.2.0","number":77}]'
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_milestone "Release Candidate v1.2.0"
  [ "$output" = "77" ]
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

# regression: --state open missed freshly-created issues — must be --state all
@test "create_issue lookup uses --state all" {
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--state all"* ]]
}

# regression: --search hits GitHub's search index (has indexing lag) — must list directly
@test "create_issue lookup does not use --search" {
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"--search"* ]]
}

@test "create_issue body references the tracked title" {
  run create_issue "Release Candidate v1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"Tracking issue for Release Candidate v1.2.0"* ]]
}

@test "create_issue returns first match when multiple share title" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "issue list"* ]]; then
  echo '[{"title":"Release Candidate v1.2.0","number":99},{"title":"Release Candidate v1.2.0","number":100}]'
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/gh"
  run create_issue "Release Candidate v1.2.0"
  [ "$output" = "99" ]
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

@test "create_branch passes --checkout flag" {
  run create_branch "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"--checkout"* ]]
}

@test "create_branch fetches and checks out branch when gh issue develop fails" {
  cat > "$BATS_TEST_TMPDIR/bin/gh" << MOCK
#!/usr/bin/env bash
echo "gh \$*" >> $CALL_LOG
if [[ "\$*" == "issue develop"* ]]; then
  exit 1
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

@test "open_pr lookup filters by --state open" {
  run open_pr "Release Candidate v1.2.0" "42" "master" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"pr list"*"--state open"* ]]
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
