## Prerequisites

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

## Key Reference Repositories

You should clone them in a proper place. In the development procedure, we will use them as reference.
Here are their description documents:

- [dify](./references/dify.md)
- [dify-official-plugins](./references/dify-official-plugins.md)
- [dify-plugin-daemon](./references/dify-plugin-daemon.md)
- [dify-plugin-sdk](./references/dify-plugin-sdk.md)
- [dify-docs](./references/dify-docs.md)
