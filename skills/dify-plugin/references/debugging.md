# Debugging & Deployment

## Remote Debugging Setup

1. **Get Debug Credentials**

   Ask user for:
   - Dify host URL (e.g., `https://your-dify.com`)
   - Email and password (suggest creating a dedicated user/workspace for development)

   Then run the script to get debugging key:

   ```bash
   # From skill directory
   python scripts/get_debug_key.py \
     --host https://your-dify.com \
     --email user@example.com \
     --password yourpassword

   # Or output directly as .env format
   python scripts/get_debug_key.py \
     --host https://your-dify.com \
     --email user@example.com \
     --password yourpassword \
     --output-env > .env
   ```

   Script location: [scripts/get_debug_key.py](../scripts/get_debug_key.py)

   **What the script does:**
   - Login: `POST {host}/console/api/login`
   - Get key: `GET {host}/console/api/workspaces/current/plugin/debugging-key`

2. **Configure .env**

   ```
   INSTALL_METHOD=remote
   REMOTE_INSTALL_HOST=https://your-dify.com
   REMOTE_INSTALL_PORT=5003
   REMOTE_INSTALL_KEY=your-debug-key
   ```

3. **Run Plugin**
   ```bash
   uv run python -m main
   ```

## Common Issues

### ModuleNotFoundError: dify_plugin

```bash
uv add dify_plugin
uv sync
```

### Plugin.**init**() missing config

Update `main.py`:

```python
from dify_plugin import DifyPluginEnv, Plugin
plugin = Plugin(DifyPluginEnv())
```

### YAML Validation Errors

Check required fields:

- `identity.description` in provider.yaml
- `extra.python.source` pointing to correct file
- `created_at` in manifest.yaml

### Handshake Failed

- Verify `REMOTE_INSTALL_KEY` is correct
- Check Dify version compatibility (requires 1.10+)

## Packaging

```bash
# Package plugin
dify plugin package ./my-plugin

# Verify package
dify plugin checksum ./my-plugin.difypkg

# Run packaged plugin (for testing)
dify plugin run ./my-plugin.difypkg
```

## Deployment Options

| Method                 | Description                              |
| ---------------------- | ---------------------------------------- |
| **Remote Debug**       | Development, connects to Dify instance   |
| **Plugin Marketplace** | Upload .difypkg to marketplace           |
| **Self-hosted**        | Deploy alongside Dify with plugin daemon |

## pyproject.toml Dependencies

```toml
[project]
name = "my-plugin"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "dify_plugin>=0.1.0",
    "httpx>=0.27.0",
]
```
