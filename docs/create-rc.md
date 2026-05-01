# create-rc

Creates a milestone, a tracking issue, an `rc-*` branch, and a PR for a target release version.

Given `version: 1.2.0`, the action produces:
- Milestone: `Release Candidate v1.2.0`
- Issue: `Release Candidate v1.2.0` (linked to milestone)
- Branch: `rc-1.2.0` (linked to issue)
- Commit: `chore: bump version to 1.2.0-rc.1`
- PR: `Release Candidate v1.2.0` → `Closes #<issue>`

## Inputs

| Name | Required | Default | Description |
|---|---|---|---|
| `version` | Yes | — | Target stable version (`1.2.0` or `v1.2.0`) |
| `bump-command` | Yes | — | Command to set the version. `VERSION` env var is set to the rc version (e.g. `1.2.0-rc.1`) |
| `base-branch` | No | `main` | Branch to cut from and open the PR against |
| `token` | Yes | — | GitHub token with `contents:write` and `pull-requests:write` |

## Workflow example

```yaml
# .github/workflows/create-rc.yml
name: Create Release Candidate

on:
  workflow_dispatch:
    inputs:
      version:
        description: "Target version (e.g. 1.2.0)"
        required: true

permissions:
  contents: write
  pull-requests: write
  issues: write

jobs:
  create-rc:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}
          fetch-depth: 0

      - uses: Bytenana-Actions/create-rc@v1
        with:
          version: ${{ inputs.version }}
          bump-command: bump-my-version bump --new-version $VERSION --no-commit
          token: ${{ secrets.GITHUB_TOKEN }}
```

## bump-command examples

**bump-my-version**
```yaml
bump-command: bump-my-version bump --new-version $VERSION --no-commit
```

**npm**
```yaml
bump-command: npm version $VERSION --no-git-tag-version
```

**poetry**
```yaml
bump-command: poetry version $VERSION
```
