---
name: dify-plugin
description: Build Dify plugins (Tool, Trigger, Extension, Model, Datasource, Agent Strategy). Use when integrating external APIs, adding webhooks, implementing model providers, connecting data sources, or creating custom agent reasoning strategies. Supports Python SDK with YAML configurations.
---

## Plugin Types Overview

- **Tool** - Add capabilities: API calls, logic operations, file processing
    - Usage: Add capability to workflow/agent
    - Reference: [tool-plugin.md](plugin-guide-by-category/tool-plugin.md)
    - Example: `tools/wikipedia`, `tools/github`

- **Trigger** - Start workflows from webhooks
    - Usage: Start workflow when webhook received
    - Reference: [trigger-plugin.md](plugin-guide-by-category/trigger-plugin.md)
    - Example: `triggers/github_trigger`

- **Extension** - Custom HTTP endpoints
    - Usage: Expose HTTP endpoint (OAuth, webhook)
    - Reference: [extension-plugin.md](plugin-guide-by-category/extension-plugin.md)
    - Example: `extensions/slack_bot`

- **Model** - Add AI model providers
    - Usage: Add AI model to workflow/agent
    - Reference: [model-plugin.md](plugin-guide-by-category/model-plugin.md)
    - Example: `models/openai`, `models/anthropic`

- **Datasource** - Connect external storage
    - Usage: Import docs from cloud storage
    - Reference: [datasource-plugin.md](plugin-guide-by-category/datasource-plugin.md)
    - Example: `datasources/github`

- **Agent Strategy** - Custom agent reasoning
    - Usage: Customize agent reasoning
    - Reference: [agent-strategy-plugin.md](plugin-guide-by-category/agent-strategy-plugin.md)
    - Example: `agent-strategies/cot_agent`

## Development SOP

### Phase 1: Understand Requirements

If there's not a proper plan for implementing the plugin and the plugin is not implemented yet,
you should follow [plan-for-plugin.md](plan-for-plugin.md) to prepare a plan before starting.

### Phase 2: Initialize Project

If the development environment is not set up yet or the project is not initialized yet,
you should refer to [init-development-environement.md](init-development-environement.md)

### Phase 3: Implement

If the plugin is not fully implemented yet, you should refer to [implement-plugin/SKILL.md](./implement-plugin/SKILL.md)

### Phase 4: Test & Debug

For testing plugin locally, refer to [test-plugin-locally/SKILL.md](./test-plugin-locally/SKILL.md)
For debugging plugin remotely, refer to [remote-debug-plugin.md](remote-debug-plugin.md)

### Phase 5: Package & Deploy

```bash
dify plugin package <path/to/plugin>
```

When the plugin is ready, you may ask user to try it.

### Troubleshooting

Please refer to [common-issues-and-check.md](./common-issues-and-check.md) for a detailed troubleshooting guide.

## Plugin Structure Overview (`tool` Plugin for Example)

```
my-plugin/
├── manifest.yaml         # Plugin metadata
├── main.py               # Plugin Entry
├── pyproject.toml        # Dependencies
├── provider/
│   ├── provider.yaml     # Credentials + config
│   └── provider.py       # Validation logic
├── tools/                # Tool plugins
│   ├── tool.yaml
│   └── tool.py
└── _assets/
    └── icon.svg
```

## References

Run `tree` on the root of the skill to see the structure.
