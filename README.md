## Usage

```yaml
- uses: Bytenana-Actions/create-rc@v0.1.0
  with:
    version: ${{ inputs.version }}
    bump-command: bump-my-version bump --new-version $VERSION --no-commit
    token: ${{ secrets.GITHUB_TOKEN }}
```

See [docs/create-rc.md](docs/create-rc.md) for full reference.
