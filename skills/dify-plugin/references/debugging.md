# Debugging & Deployment

## Local Integration Testing Environment

For integration testing, we set up a local Dify instance using Docker Compose. This ensures version consistency between the plugin and Dify services.

### 1. Sync Reference Repositories

First, sync the reference repositories (see [preparation.md](./preparation.md#reference-repositories-optional) for details):

```bash
./scripts/sync_repos.sh
```

### 2. Start Dify Services

```bash
cd ~/playground/dify-repo/dify/docker

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

### 3. Initial Setup

On first launch, create an admin account through the web UI:
1. Open http://localhost in browser
2. Follow the setup wizard to create admin account
3. Note the email and password for later use

### 4. Environment Variables

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

### 5. Upgrade Workflow

When upgrading Dify version:

```bash
# 1. Sync repos and switch to new version
./scripts/sync_repos.sh

# 2. Stop current services
cd ~/playground/dify-repo/dify/docker
docker compose down

# 3. Sync environment variables (optional but recommended)
./dify-env-sync.sh

# 4. Pull new images and restart
docker compose pull
docker compose up -d
```

### 6. Useful Commands

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

---

## Remote Debugging Setup

1. **Get Debug Credentials**

   For local instance (from above setup):
   - Host URL: `http://localhost`
   - Use the admin account created during initial setup

   For remote instance, ask user for:
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
