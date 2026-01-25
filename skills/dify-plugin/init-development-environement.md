## Prerequisites

### Reference Repositories (CRITICAL)

Before developing any Dify plugin, you **MUST** have these repositories available locally. They provide essential context for understanding plugin architecture, finding implementation examples, and debugging issues.

| Repository | Purpose | When to Use |
|------------|---------|-------------|
| [dify](https://github.com/langgenius/dify) | Core platform | Understand manifest schemas, daemon client, workflow integration |
| [dify-plugin-daemon](https://github.com/langgenius/dify-plugin-daemon) | Plugin runtime | CLI commands, protocol specs, runtime behavior |
| [dify-official-plugins](https://github.com/langgenius/dify-official-plugins) | Official examples | Find similar plugins to reference, copy patterns |
| [dify-plugin-sdks](https://github.com/langgenius/dify-plugin-sdks) | Python/Go SDKs | SDK source code, decorators, helper classes |
| [dify-docs](https://github.com/langgenius/dify-docs) | Documentation | Guides, API references, best practices |

#### Setup SOP

**Step 1: Ask user where to clone repositories**

Ask the user where they want to store these reference repositories.

Recommended location: `~/Source/dify-dev-reference-repo`

**Step 2: Clone repositories (Script or Manual)**

Option A - Use the setup script (interactive):
```bash
./scripts/setup-repositories.sh
# Script will prompt for directory, recommend ~/Source/dify-dev-reference-repo
```

Option B - Use the setup script with path:
```bash
./scripts/setup-repositories.sh <user-specified-path>
```

Option C - Manual clone:
```bash
# Create directory (use the path user specified)
mkdir -p <user-specified-path> && cd <user-specified-path>

# Clone all repositories
git clone https://github.com/langgenius/dify.git
git clone https://github.com/langgenius/dify-plugin-daemon.git
git clone https://github.com/langgenius/dify-official-plugins.git
git clone https://github.com/langgenius/dify-plugin-sdks.git
git clone https://github.com/langgenius/dify-docs.git
```

**Step 3: Add to Claude Code Working Directories**

After cloning, add these paths to Claude Code for enhanced context:

```bash
# Replace <repo-path> with the actual path user chose
/settings add workingDirectories <repo-path>/dify
/settings add workingDirectories <repo-path>/dify-plugin-daemon
/settings add workingDirectories <repo-path>/dify-official-plugins
/settings add workingDirectories <repo-path>/dify-plugin-sdks
/settings add workingDirectories <repo-path>/dify-docs
```

This enables Claude to search across all repositories when answering questions or finding examples.

---

### `uv`

Check if `uv` available on your runtime:

```bash
uv --version
```

If not:

For MacOS/Linux:
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

For Windows:
```bash
powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

### Dify CLI

Check if `dify` available on your runtime:

```bash
dify version
```

If not:

With `homebrew`:

```bash
brew tap langgenius/dify && brew install dify
```

Download the binary from [releases](https://github.com/langgenius/dify-plugin-daemon/releases).

## Setup Project

```bash
# Show help
dify plugin init --help

# Create plugin scaffold according to the help
dify plugin init --quick --name <plugin-name> --category <plugin-category> --description <plugin-description> <other-flags>

cd <plugin_name>

# Always use uv for plugin development
uv init --no-readme
uv add dify_plugin
```

## Reference Documentation

For detailed information about each repository's structure and how to use them during development:

- [dify](./references/dify.md) - Core platform architecture
- [dify-official-plugins](./references/dify-official-plugins.md) - Official plugin examples
- [dify-plugin-daemon](./references/dify-plugin-daemon.md) - CLI and runtime
- [dify-plugin-sdk](./references/dify-plugin-sdk.md) - Python SDK details
- [dify-docs](./references/dify-docs.md) - Documentation structure
