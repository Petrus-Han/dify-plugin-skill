# Publishing Dify Plugins

When the user wants to publish a plugin, **always ask them to choose** between:

1. **Dify Marketplace** — Official plugin marketplace, public and discoverable
2. **GitHub Release** — `.difypkg` file attached to a GitHub Release, for private/self-hosted deployment

Use `AskUserQuestion` to let the user choose before proceeding.

---

## Option A: Publish to Dify Marketplace (Auto-PR)

The Marketplace uses a GitHub-based workflow: push to main → GitHub Actions packages the plugin → auto-creates a PR to `langgenius/dify-plugins`.

Reference: https://docs.dify.ai/plugins/publish-plugins/publish-to-dify-marketplace

### Prerequisites

1. **Fork `langgenius/dify-plugins`** to the author's GitHub account
2. **Create `PLUGIN_ACTION` secret** in the plugin source repo:
   - Go to repo Settings → Secrets and variables → Actions → New repository secret
   - Name: `PLUGIN_ACTION`
   - Value: GitHub PAT with write access to the forked `dify-plugins` repo

### Setup: Add GitHub Actions Workflow

Copy the workflow template from [`scripts/plugin-publish.yml`](scripts/plugin-publish.yml) to the plugin source repo at `.github/workflows/plugin-publish.yml`.

Use the `Read` tool to read `scripts/plugin-publish.yml` from this skill directory, then use the `Write` tool to create `.github/workflows/plugin-publish.yml` in the plugin repo.

What it does on each push to `main`:
1. Downloads the pinned version of Dify CLI (update `DIFY_CLI_VERSION` env var as needed)
2. Reads `name`, `version`, `author` from `manifest.yaml` using `yq`
3. Packages the plugin as `{name}-{version}.difypkg`
4. Checks out `{author}/dify-plugins` fork
5. Copies the `.difypkg` into `{author}/{plugin-name}/` directory
6. Creates branch `bump-{plugin-name}-plugin-{version}` and pushes
7. Opens PR to `langgenius/dify-plugins` via `gh pr create`

### Publishing Steps (after initial setup)

1. Bump `version` in `manifest.yaml` (e.g., `0.0.1` → `0.0.2`)
2. Commit and push to `main` branch
3. GitHub Actions automatically:
   - Downloads pinned Dify CLI
   - Packages the plugin as `{name}-{version}.difypkg`
   - Pushes to `{author}/dify-plugins` fork, branch `bump-{name}-plugin-{version}`
   - Creates PR to `langgenius/dify-plugins`
4. Dify team reviews and merges the PR → plugin appears in Marketplace

### manifest.yaml Requirements for Marketplace

```yaml
version: 0.0.2          # Bump this each release (semver)
author: your-github-id  # Must match your GitHub username and fork path
name: your-plugin-name  # Determines package name and directory
```

### Checklist Before Publishing

- [ ] Version bumped in `manifest.yaml`
- [ ] No `.venv`/`venv`/`__pycache__` directories (use `.gitignore`)
- [ ] No hardcoded credentials or secrets
- [ ] Plugin packages successfully: `dify plugin package .`
- [ ] Plugin tested on a real Dify instance
- [ ] `PLUGIN_ACTION` secret configured with valid PAT
- [ ] `{author}/dify-plugins` fork exists and is up to date

---

## Option B: Publish to GitHub Release

For private/self-hosted deployments where the plugin doesn't need to be in the public Marketplace.

### Publishing Steps

**Dev Branch (Testing)**:
1. Update version in `manifest.yaml` with dev suffix (e.g., `0.1.0-dev.1`)
2. Package plugin: `dify plugin package <path/to/plugin>`
3. Create GitHub pre-release:
   ```bash
   gh release create v0.1.0-dev.1 \
     --repo <owner>/<repo> \
     --title "v0.1.0-dev.1" \
     --prerelease \
     <plugin-name>.difypkg
   ```

**Main Branch (Production)**:
1. Update version in `manifest.yaml` with release number (e.g., `0.1.0`)
2. Package plugin: `dify plugin package <path/to/plugin>`
3. Create GitHub release:
   ```bash
   gh release create v0.1.0 \
     --repo <owner>/<repo> \
     --title "v0.1.0" \
     --generate-notes \
     <plugin-name>.difypkg
   ```

### Installing from GitHub Release

Users download the `.difypkg` file from the release and install via:

```bash
# Via install script
uv run python scripts/install_plugin.py <plugin-name>.difypkg

# Or upload manually in Dify UI: Plugins → Upload Plugin
```
