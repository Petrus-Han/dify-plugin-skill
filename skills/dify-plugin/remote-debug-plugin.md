# Remote Debugging Plugin

## Local Integration Testing Environment

For integration testing, we set up a local Dify instance using Docker Compose. This ensures version consistency between the plugin and Dify services.

### Version Control

You should keep `dify` being the latest version in your local repo.

### Start Dify Services

```bash
cd <dify-path>/docker

# Copy environment file (first time only)
cp .env.example .env

# Start all services
docker compose up -d

# Check service status
docker compose ps
```

**Key services started:**
| Service | Port | Description |
|---------|------|-------------|
| nginx | 80/443 | Reverse proxy |
| api | 5001 | Dify API server |
| web | 3000 | Dify web frontend |
| worker | - | Background task worker |
| plugin_daemon | 5003 | Plugin daemon for debugging |
| db | 5432 | PostgreSQL database |
| redis | 6379 | Redis cache |

**Access Dify:**
- Web UI: http://localhost (or http://localhost:80)
- API: http://localhost/console/api

### Initial Setup

On first launch, create an admin account through the web UI:
1. Open http://localhost in browser
2. Follow the setup wizard to create admin account
3. Note the email and password for later use

### Environment Variables

Important `.env` settings for plugin development:

```bash
# Enable plugin daemon (already enabled by default)
PLUGIN_DAEMON_ENABLED=true

# Plugin daemon port (for remote debugging)
PLUGIN_DAEMON_PORT=5003

# Debug mode (optional, for verbose logging)
DEBUG=true
LOG_LEVEL=DEBUG
```

### Upgrade Workflow

When upgrading Dify version:

```bash
cd <dify-path>
git pull

# 2. Stop current services
cd docker
docker compose down

# 3. Sync environment variables (optional but recommended)
./dify-env-sync.sh

# 4. Pull new images and restart
docker compose pull
docker compose up -d
```

### Useful Commands

```bash
# View logs
docker compose logs -f api          # API server logs
docker compose logs -f plugin_daemon # Plugin daemon logs

# Restart specific service
docker compose restart plugin_daemon

# Stop all services
docker compose down

# Stop and remove volumes (clean reset)
docker compose down -v
```

## Remote Debugging Setup

1. **Get Debug Credentials**

   The script automatically manages credentials via a `.credential` file:

   ```bash
   # First time: prompts for credentials interactively and saves to .credential
   uv run python scripts/get_debug_key.py

   # Subsequent runs: automatically loads from .credential
   uv run python scripts/get_debug_key.py

   # Output directly as .env format
   uv run python scripts/get_debug_key.py --output-env > .env
   ```

   **Credential file workflow:**
    - First run: Script prompts for Dify host URL, email, and password
    - Credentials are saved to `.credential` (JSON format, 600 permissions)
    - `.credential` is gitignored to prevent accidental commits
    - Subsequent runs automatically use saved credentials

   **For local Dify instance:**
    - Host URL: `http://localhost`
    - Use the admin account created during initial setup

   **For remote instance:**
    - Dify host URL (e.g., `https://your-dify.com`)
    - Suggest creating a dedicated user/workspace for development

   **Script options:**
   ```bash
   # Override specific credentials while using saved values for others
   uv run python scripts/get_debug_key.py --host https://new-host.com

   # Specify custom credential file location
   uv run python scripts/get_debug_key.py --credential-file /path/to/.credential

   # Don't save credentials (one-time use)
   uv run python scripts/get_debug_key.py --no-save --host <url> --email <email> --password <pwd>
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

   Use the debug script to automatically kill any previous debug process before starting:

   ```bash
   # Recommended: auto-kills previous process
   ./scripts/debug.sh

   # Or use directly (won't auto-kill previous process)
   uv run python -m main
   ```

   **Debug script options:**
   ```bash
   # Kill existing debug process without starting new one
   ./scripts/debug.sh --kill-only

   # Check if a debug process is running
   ./scripts/debug.sh --status

   # Show help
   ./scripts/debug.sh --help
   ```

   The debug script:
    - Automatically finds and kills any existing debug process for the current plugin
    - Stores process ID in `.debug.pid` for reliable process management
    - Handles graceful shutdown with fallback to force-kill
    - Properly cleans up on Ctrl+C

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

## Debugging Common Errors

### "permission denied, you need to enable llm access"
**Cause**: Tool uses `self.session.model.summary.invoke()` without model permission.
**Fix**: Remove LLM calls, return JSON directly.

### "AttributeError: module 'httpx' has no attribute 'RequestException'"
**Cause**: Wrong exception type.
**Fix**: Use `httpx.HTTPError` instead.

### "401 Unauthorized" in production
**Cause**: Using sandbox credentials in production.
**Fix**: Add environment selection to provider.

### "404 Not Found" on API calls
**Cause**: Wrong API base URL.
**Fix**: Verify URL construction and environment logic.

**Important**: Before debugging, You should automatically fetch the debug key using saved credentials. If credentials don't exist, prompt the user once and save to `.credential`.

```bash
# Get debug key (auto-loads from .credential, or prompts first time)
   uv run python scripts/get_debug_key.py

# Output directly to plugin's .env file
   uv run python scripts/get_debug_key.py --output-env > .env

# Run plugin in debug mode (auto-kills previous process)
./scripts/debug.sh

# Or use directly (won't auto-kill previous process)
uv run python -m main
```

**Credential workflow:**
- First time: Script prompts for Dify host, email, password → saves to `.credential`
- Subsequent runs: Automatically uses saved credentials
- `.credential` is gitignored (contains sensitive login info)
