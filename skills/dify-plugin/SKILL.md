---
name: dify-plugin
description: Build Dify plugins (Tool, Trigger, Extension, Model, Datasource, Agent Strategy). Use when integrating external APIs, adding webhooks, implementing model providers, connecting data sources, or creating custom agent reasoning strategies. Supports Python SDK with YAML configurations.
---

# Dify Plugin Development

## Quick Start

```bash
# Install tools
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

## Development Workflow

1. **Plan** - Identify plugin type, read API docs, check [plugins_reference.md](references/plugins_reference.md)
2. **Create** - Run `dify plugin init`, setup dependencies
3. **Implement** - Write provider.yaml, tool/trigger/model files
4. **Test** - Validate credentials, test with Dify remote debugging
5. **Package** - Run `dify plugin package`, upload to Dify

## Core Structure

```
my-plugin/
├── manifest.yaml          # Plugin metadata
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

## Valid Tags

Only 19 tags accepted: `search`, `image`, `videos`, `weather`, `finance`, `design`, `travel`, `social`, `news`, `medical`, `productivity`, `education`, `business`, `entertainment`, `utilities`, `agent`, `rag`, `trigger`, `other`

## Common Patterns

### Tool Implementation

```python
from dify_plugin import Tool
from dify_plugin.entities.tool import ToolInvokeMessage

class MyTool(Tool):
    def _invoke(self, tool_parameters: dict) -> Generator[ToolInvokeMessage, None, None]:
        api_key = self.runtime.credentials["api_key"]
        result = self._call_api(tool_parameters.get("query"))
        yield self.create_json_message(result)
```

### Credential Validation

```python
from dify_plugin import ToolProvider
from dify_plugin.errors.tool import ToolProviderCredentialValidationError

class MyProvider(ToolProvider):
    def _validate_credentials(self, credentials: dict) -> None:
        if not credentials.get("api_key"):
            raise ToolProviderCredentialValidationError("API Key required")
```

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `permission denied, you need to enable llm access` | LLM call without permission | Remove LLM calls or set `permission.model.enabled: true` |
| `httpx.RequestException` | Wrong exception type | Use `httpx.HTTPError` |
| `Tags[X] failed on plugin_tag` | Invalid tag | Use only valid 19 tags |
| `401 Unauthorized` | Wrong credentials | Check environment (sandbox vs production) |

## Best Practices

- Return JSON with `create_json_message()` for structured data
- Use `httpx.HTTPError` for exception handling
- Set `timeout=30` for HTTP calls
- Don't use LLM just for formatting
- One plugin per API service, one tool per operation

## References

- [tool-plugin.md](references/tool-plugin.md) - Tool plugin details
- [trigger-plugin.md](references/trigger-plugin.md) - Trigger plugin details
- [model-plugin.md](references/model-plugin.md) - Model plugin details
- [extension-plugin.md](references/extension-plugin.md) - Extension plugin details
- [datasource-plugin.md](references/datasource-plugin.md) - Datasource plugin details
- [agent-strategy-plugin.md](references/agent-strategy-plugin.md) - Agent Strategy plugin details
- [yaml-schemas.md](references/yaml-schemas.md) - Complete YAML templates
- [plugins_reference.md](references/plugins_reference.md) - Official plugin examples
- [debugging.md](references/debugging.md) - Debugging techniques
