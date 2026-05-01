#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="${GITHUB_ACTION_PATH}/scripts"
source "${SCRIPT_DIR}/versions.sh"
source "${SCRIPT_DIR}/git.sh"
source "${SCRIPT_DIR}/github.sh"

# ── Versions ────────────────────────────────────────────────────────────────
echo "::group::Compute versions"
compute_versions "$INPUT_VERSION"
echo "  stable:   ${STABLE}"
echo "  rc:       ${RC_VERSION}"
echo "  branch:   ${BRANCH}"
echo "  title:    ${RC_TITLE}"
echo "::endgroup::"

# ── Git ──────────────────────────────────────────────────────────────────────
echo "::group::Configure git"
configure_git
echo "  user: github-actions[bot]"
echo "::endgroup::"

# ── Milestone ────────────────────────────────────────────────────────────────
echo "::group::Create milestone"
MILESTONE_NUMBER=$(create_milestone "${RC_TITLE}")
echo "  created milestone #${MILESTONE_NUMBER}: ${RC_TITLE}"
echo "::endgroup::"

# ── Issue ────────────────────────────────────────────────────────────────────
echo "::group::Create issue"
ISSUE_NUMBER=$(create_issue "${RC_TITLE}")
echo "  created issue #${ISSUE_NUMBER}: ${RC_TITLE}"
echo "::endgroup::"

# ── Branch ───────────────────────────────────────────────────────────────────
echo "::group::Create branch"
create_branch "${ISSUE_NUMBER}" "${INPUT_BASE_BRANCH}" "${BRANCH}"
echo "  created branch: ${BRANCH} (linked to issue #${ISSUE_NUMBER})"
echo "::endgroup::"

# ── Bump version ─────────────────────────────────────────────────────────────
echo "::group::Bump version"
echo "  running: ${INPUT_BUMP_COMMAND}"
export VERSION="${RC_VERSION}"
bash -c "${INPUT_BUMP_COMMAND}"
echo "::endgroup::"

# ── Commit and push ──────────────────────────────────────────────────────────
echo "::group::Commit and push"
commit_and_push "chore: bump version to ${RC_VERSION}" "${BRANCH}"
echo "  pushed branch: ${BRANCH}"
echo "::endgroup::"

# ── PR ───────────────────────────────────────────────────────────────────────
echo "::group::Open PR"
open_pr "${RC_TITLE}" "${ISSUE_NUMBER}" "${INPUT_BASE_BRANCH}" "${BRANCH}"
echo "  opened PR: ${RC_TITLE} → ${INPUT_BASE_BRANCH}"
echo "::endgroup::"

echo "::notice title=Release Candidate Ready::${RC_TITLE} — branch ${BRANCH}, issue #${ISSUE_NUMBER}"
