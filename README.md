## Usage

```yaml
- uses: Bytenana-Actions/create-rc@v1
  with:
    version: ${{ inputs.version }}
    bump-command: bump-my-version bump --new-version $VERSION --no-commit
    token: ${{ secrets.GITHUB_TOKEN }}
```

See [docs/create-rc.md](docs/create-rc.md) for full reference.
