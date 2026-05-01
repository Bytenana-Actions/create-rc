#!/usr/bin/env bats

setup() {
  source "${BATS_TEST_DIRNAME}/../scripts/versions.sh"
}

@test "strips v prefix" {
  compute_versions "v1.2.0"
  [ "$STABLE" = "1.2.0" ]
}

@test "no v prefix passes through" {
  compute_versions "1.2.0"
  [ "$STABLE" = "1.2.0" ]
}

@test "appends rc.1 suffix" {
  compute_versions "1.2.0"
  [ "$RC_VERSION" = "1.2.0-rc.1" ]
}

@test "branch name is rc-<stable>" {
  compute_versions "1.2.0"
  [ "$BRANCH" = "rc-1.2.0" ]
}

@test "title format" {
  compute_versions "1.2.0"
  [ "$RC_TITLE" = "Release Candidate v1.2.0" ]
}

@test "v prefix stripped but title keeps v" {
  compute_versions "v2.0.0"
  [ "$STABLE" = "2.0.0" ]
  [ "$RC_TITLE" = "Release Candidate v2.0.0" ]
}
