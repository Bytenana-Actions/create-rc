#!/usr/bin/env bats

setup() {
  mkdir -p "$BATS_TEST_TMPDIR/bin"
  export PATH="$BATS_TEST_TMPDIR/bin:$PATH"
  CALL_LOG="$BATS_TEST_TMPDIR/calls"

  cat > "$BATS_TEST_TMPDIR/bin/git" << MOCK
#!/usr/bin/env bash
echo "git \$*" >> $CALL_LOG
MOCK
  chmod +x "$BATS_TEST_TMPDIR/bin/git"

  source "${BATS_TEST_DIRNAME}/../scripts/git.sh"
}

@test "configure_git sets user.name to github-actions[bot]" {
  run configure_git
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"config user.name github-actions[bot]"* ]]
}

@test "configure_git sets user.email" {
  run configure_git
  [[ "$(cat "$BATS_TEST_TMPDIR/calls")" == *"config user.email github-actions[bot]@users.noreply.github.com"* ]]
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
