#!/usr/bin/env bats

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  CALL_LOG="$BATS_TEST_TMPDIR/calls"

  # Default mock: simulates CI (no git identity set, staged changes present)
  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
if [[ "\$*" == "diff --cached --quiet" ]]; then
  exit 1
fi
if [[ "\$*" == "config user.name" || "\$*" == "config user.email" ]]; then
  exit 1
fi
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"

  source "${BATS_TEST_DIRNAME}/../scripts/git.sh"
}

@test "configure_git sets user.name when not configured" {
  run configure_git
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"config user.name github-actions[bot]"* ]]
}

@test "configure_git sets user.email when not configured" {
  run configure_git
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"config user.email github-actions[bot]@users.noreply.github.com"* ]]
}

@test "configure_git does not overwrite existing user.name" {
  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"
  run configure_git
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"config user.name github-actions[bot]"* ]]
}

@test "configure_git does not overwrite existing user.email" {
  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"
  run configure_git
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" != *"config user.email github-actions[bot]@users.noreply.github.com"* ]]
}

@test "commit_and_push stages all tracked changes" {
  run commit_and_push "chore: bump version to 1.2.0-rc.1" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"git add -u"* ]]
}

@test "commit_and_push commits with the given message" {
  run commit_and_push "chore: bump version to 1.2.0-rc.1" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"commit -m chore: bump version to 1.2.0-rc.1"* ]]
}

@test "commit_and_push pushes to the correct branch" {
  run commit_and_push "chore: bump version to 1.2.0-rc.1" "rc-1.2.0"
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"push origin rc-1.2.0"* ]]
}

@test "commit_and_push fails when bump-command modified no tracked files" {
  # override mock: diff --cached --quiet exits 0 = nothing staged
  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"

  run commit_and_push "chore: bump version to 1.2.0-rc.1" "rc-1.2.0"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no tracked files were modified"* ]]
}
