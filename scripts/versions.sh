#!/usr/bin/env bash

compute_versions() {
  local input="$1"
  STABLE="${input#v}"
  RC_VERSION="${STABLE}-rc.1"
  BRANCH="rc-${STABLE}"
  RC_TITLE="Release Candidate v${STABLE}"
}
