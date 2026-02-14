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
author: your-github-id  # Must NOT be "langgenius" or "dify"
name: your-plugin-name  # Determines package name and directory
icon: icon.svg          # Must exist at _assets/icon.svg
```

### Marketplace CI Checks (`pre-check-plugin`)

The `langgenius/dify-plugins` repo runs automated CI on every PR. All checks must pass before merge:

| Check | What It Validates |
|-------|-------------------|
| **Single .difypkg** | Only ONE `.difypkg` file change per PR |
| **PR language** | PR title/body must not contain CJK characters |
| **Project structure** | Must include `README.md` and `PRIVACY.md` in plugin root |
| **Manifest** | `author` must not be `langgenius` or `dify` |
| **Icon** | Icon file must exist at `_assets/{icon}`, must not be default template or contain `DIFY_MARKETPLACE_TEMPLATE_ICON_DO_NOT_USE` |
| **Version** | Version must not already exist in marketplace (`marketplace.dify.ai/api/v1/plugins/{author}/{name}/{version}`) |
| **README language** | `README.md` must not contain Chinese characters (use multilingual README for i18n) |
| **PRIVACY.md** | `PRIVACY.md` must exist in plugin root |
| **Dependencies** | `requirements.txt` must install cleanly (Python 3.12) |
| **dify_plugin version** | `dify_plugin >= 0.5.0` required |
| **Install Test** | Plugin must pass install test via `dify-plugin-daemon` |
| **Packaging** | Plugin must pass marketplace toolkit packaging validation |

### Required Files for Marketplace

Every plugin **must** include these files in the plugin root (they get packaged into the `.difypkg`):

- **`README.md`** — Plugin description, usage, configuration. Must be in **English** (no Chinese). For multilingual support, see [multilingual README docs](https://docs.dify.ai/en/develop-plugin/features-and-specs/plugin-types/multilingual-readme#multilingual-readme).
- **`PRIVACY.md`** — Privacy policy describing what data the plugin collects, stores, and transmits.
- **`_assets/icon.svg`** — Custom icon (not default template).

After merge, `upload-merged-plugin` workflow automatically uploads the `.difypkg` to the Dify Marketplace.

**First-time fork contributors**: CI requires maintainer approval before running (GitHub security policy). The Dify team will approve the workflow run from the Actions tab.

### PR Review & Fix Loop (SOP)

After creating a PR, follow this loop until CI passes and the PR is approved:

1. **Submit PR** — Create PR to `langgenius/dify-plugins`
2. **Wait for CI** — Check CI status with `gh pr checks <PR#> --repo langgenius/dify-plugins`. For first-time forks, CI needs maintainer approval (`action_required`).
3. **Read CI results** — If CI fails, read the workflow run logs:
   ```bash
   gh run view <run-id> --repo langgenius/dify-plugins --log-failed
   ```
4. **Fix issues** — Address each failing check:
   - Missing `README.md` / `PRIVACY.md` → Add the files to the plugin, repackage
   - CJK in README → Rewrite in English
   - Icon validation → Replace with custom icon
   - Version exists → Bump version in `manifest.yaml`
   - Install test failed → Debug the plugin startup (check `main.py`, imports, dependencies)
   - Packaging failed → Ensure `dify plugin package .` succeeds locally
5. **Repackage & re-push** — After fixing:
   ```bash
   dify plugin package <plugin> -o <name>-<version>.difypkg
   # Copy to fork branch, commit, push (triggers CI re-run via `synchronize` event)
   ```
6. **Repeat** until all checks pass

**Important**: Each push to the fork branch triggers a new CI run. For fork PRs, each `synchronize` event may again require maintainer approval.

### Manual Publishing (without Auto-PR workflow)

If the auto-PR workflow is not set up, you can publish manually:

```bash
# 1. Package the plugin
dify plugin package <path/to/plugin> -o <name>-<version>.difypkg

# 2. Clone your fork of langgenius/dify-plugins
git clone https://github.com/<your-fork>/dify-plugins.git /tmp/dify-plugins
cd /tmp/dify-plugins

# 3. Sync fork with upstream
git remote add upstream https://github.com/langgenius/dify-plugins.git
git fetch upstream main && git reset --hard upstream/main

# 4. Create branch, copy package, push
git checkout -b bump-<name>-plugin-<version>
mkdir -p <author>/<name>
cp <name>-<version>.difypkg <author>/<name>/
git add . && git commit -m "bump <name> plugin to version <version>"
git push -u origin bump-<name>-plugin-<version>

# 5. Create PR (one PR per plugin)
gh pr create \
  --repo langgenius/dify-plugins \
  --head "<fork-owner>:bump-<name>-plugin-<version>" \
  --base main \
  --title "bump <name> plugin to version <version>" \
  --body "bump <name> plugin package to version <version>"
```

### Checklist Before Publishing

- [ ] Version bumped in `manifest.yaml`
- [ ] `author` is not `langgenius` or `dify`
- [ ] Custom icon at `_assets/icon.svg` (not default template)
- [ ] `README.md` exists in plugin root (English only, no CJK characters)
- [ ] `PRIVACY.md` exists in plugin root
- [ ] Version does not already exist in marketplace
- [ ] No `.venv`/`venv`/`__pycache__` directories (use `.gitignore`)
- [ ] No hardcoded credentials or secrets
- [ ] Plugin packages successfully: `dify plugin package .`
- [ ] Plugin tested on a real Dify instance
- [ ] Only ONE `.difypkg` file changed per PR
- [ ] PR title/body in English (no CJK characters)
- [ ] `PLUGIN_ACTION` secret configured with valid PAT (if using auto-PR)
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
