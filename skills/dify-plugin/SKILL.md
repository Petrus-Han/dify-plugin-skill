---
name: dify-plugin
description: Build Dify plugins (Tool, Trigger, Extension, Model, Datasource, Agent Strategy). Use when integrating external APIs, adding webhooks, implementing model providers, connecting data sources, or creating custom agent reasoning strategies. Supports Python SDK with YAML configurations.
---

# Dify Plugin Development

## Prerequisites

See [preparation.md](references/preparation.md) for environment setup and CLI installation on different platforms.

## Quick Start

```bash
# Install tools (macOS)
brew tap langgenius/dify && brew install dify
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create plugin
dify plugin init

# Setup dependencies
cd my-plugin && uv init --no-readme && uv add dify_plugin

# Package and deploy
dify plugin package ./my-plugin
```

## Plugin Types

| Type | Purpose | Reference |
|------|---------|-----------|
| **Tool** | Integrate external APIs | [tool-plugin.md](references/tool-plugin.md) |
| **Trigger** | Start workflows from webhooks | [trigger-plugin.md](references/trigger-plugin.md) |
| **Extension** | Custom HTTP endpoints | [extension-plugin.md](references/extension-plugin.md) |
| **Model** | Add AI model providers | [model-plugin.md](references/model-plugin.md) |
| **Datasource** | Connect external storage | [datasource-plugin.md](references/datasource-plugin.md) |
| **Agent Strategy** | Custom agent reasoning | [agent-strategy-plugin.md](references/agent-strategy-plugin.md) |

## Development SOP

1. **Prepare** - Read [preparation.md](references/preparation.md), install CLI and dependencies
2. **Choose Type** - Identify plugin type from Plugin Types table above
3. **Read API Docs** - If integrating external systems, read their API documentation first
4. **Study Examples** - Check [plugins_reference.md](references/plugins_reference.md) for best practices
5. **Develop** - Run `dify plugin init`, read the corresponding plugin reference (e.g., [tool-plugin.md](references/tool-plugin.md) for Tool), implement provider and tools
6. **Test** - Validate credentials, debug with [debugging.md](references/debugging.md)

## Core Structure

```
my-plugin/
├── manifest.yaml          # Plugin metadata (see MANIFEST_REFERENCE.md)
├── main.py               # Entry: plugin = Plugin(DifyPluginEnv())
├── pyproject.toml        # Dependencies (uv)
├── provider/
│   ├── provider.yaml     # Credentials + config
│   └── provider.py       # Validation logic
├── tools/                # Tool plugins
│   ├── tool.yaml
│   └── tool.py
└── _assets/
    └── icon.svg
```

**Important**: For complete manifest.yaml field rules, validation constraints, and examples, see [MANIFEST_REFERENCE.md](references/MANIFEST_REFERENCE.md).

## Valid Tags

Only 19 tags accepted: `search`, `image`, `videos`, `weather`, `finance`, `design`, `travel`, `social`, `news`, `medical`, `productivity`, `education`, `business`, `entertainment`, `utilities`, `agent`, `rag`, `trigger`, `other`

## Best Practices

- Set `timeout=30` for HTTP calls
- Don't use LLM just for formatting
- One plugin per API service, one tool per operation

## References

### Core References
- [MANIFEST_REFERENCE.md](references/MANIFEST_REFERENCE.md) - **Complete manifest.yaml reference** (field rules, validation, examples)
- [PLUGIN_ARCHITECTURE.md](references/PLUGIN_ARCHITECTURE.md) - **Plugin architecture deep dive** (lifecycle, hooks, runtime, directory structures)

### Plugin Type References
- [tool-plugin.md](references/tool-plugin.md) - Tool plugin details
- [trigger-plugin.md](references/trigger-plugin.md) - Trigger plugin details
- [model-plugin.md](references/model-plugin.md) - Model plugin details
- [extension-plugin.md](references/extension-plugin.md) - Extension plugin details
- [datasource-plugin.md](references/datasource-plugin.md) - Datasource plugin details
- [agent-strategy-plugin.md](references/agent-strategy-plugin.md) - Agent Strategy plugin details

### Additional References
- [yaml-schemas.md](references/yaml-schemas.md) - Common YAML patterns
- [plugins_reference.md](references/plugins_reference.md) - Official plugin examples
- [debugging.md](references/debugging.md) - Debugging techniques
