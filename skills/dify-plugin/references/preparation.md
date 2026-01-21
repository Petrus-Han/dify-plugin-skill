# Environment Setup

## Quick Setup (Recommended)

Run the setup script to install all dependencies:

```bash
# From skill directory
./scripts/setup_env.sh
```

This will:
1. Check Python version (3.12+ required)
2. Install `dify` CLI
3. Install `uv` (Python package manager)

## Manual Setup

If the script fails, follow these steps manually.

### 1. Install Dify CLI

**macOS (Homebrew):**
```bash
brew tap langgenius/dify
brew install dify
```

**macOS/Linux (Manual Download):**
```bash
# Download from: https://github.com/langgenius/dify-plugin-daemon/releases

# macOS ARM (M series)
curl -fsSL https://github.com/langgenius/dify-plugin-daemon/releases/latest/download/dify-plugin-darwin-arm64 -o dify
chmod +x dify
sudo mv dify /usr/local/bin/

# macOS Intel
curl -fsSL https://github.com/langgenius/dify-plugin-daemon/releases/latest/download/dify-plugin-darwin-amd64 -o dify
chmod +x dify
sudo mv dify /usr/local/bin/

# Linux AMD64
curl -fsSL https://github.com/langgenius/dify-plugin-daemon/releases/latest/download/dify-plugin-linux-amd64 -o dify
chmod +x dify
sudo mv dify /usr/local/bin/
```

Verify: `dify version`

### 2. Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

Add to PATH if needed: `export PATH="$HOME/.local/bin:$PATH"`

Verify: `uv --version`

### 3. Check Python

```bash
python3 --version  # Should be 3.12+
```

## Create Plugin Project

```bash
# Interactive mode
dify plugin init

# Setup Python environment
cd my-plugin
uv init --no-readme
uv add dify_plugin
```

## Verify Installation

```bash
dify version          # CLI version
uv --version          # Package manager
python3 --version     # Python 3.12+
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `dify: command not found` | Add `/usr/local/bin` to PATH or reinstall |
| `uv: command not found` | Add `~/.local/bin` to PATH |
| Python < 3.12 | Install Python 3.12+ via pyenv or system package |
| Permission denied | Use `sudo` for `/usr/local/bin` install |
