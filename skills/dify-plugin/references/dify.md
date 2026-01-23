# Dify Core

Use this repository to understand how Dify itself installs, invokes, and wires plugins into workflows.

Repo: [langgenius/dify](https://github.com/langgenius/dify)

## Why it matters for this skill

- Defines plugin manifests and categories used by all plugins.
- Implements the daemon client that installs and invokes plugins.
- Shows how plugin tools and triggers participate in workflows.

## Plugin system map

### Core schemas

- `api/core/plugin/entities/plugin.py` - manifest schema, categories, permissions, resource requirements
- `api/core/plugin/entities/plugin_daemon.py` - daemon response models and install task entities

### Daemon communication

- `api/core/plugin/impl/base.py` - BasePluginClient HTTP client for daemon calls
- `api/core/plugin/impl/plugin.py` - PluginInstaller for upload/install/upgrade/uninstall
- `api/core/plugin/impl/tool.py` - tool provider listing and tool invocation via daemon
- `api/core/plugin/impl/debugging.py` - debugging key retrieval for local development

### Plugin lifecycle services

- `api/services/plugin/plugin_service.py` - install, upgrade, permissions, marketplace flows
- `api/controllers/console/workspace/plugin.py` - console APIs for plugin management

### Workflow integration

- `api/core/workflow/nodes/trigger_plugin/trigger_event_node.py` - trigger plugin node entry point
- `api/agent_skills/trigger.md` - trigger node behavior and plugin trigger flow

## Reading order

1. `api/agent_skills/infra.md` - plugin system overview and runtime topology
2. `api/core/plugin/entities/plugin.py` - manifest schema and categories
3. `api/core/plugin/impl/base.py` and `api/core/plugin/impl/plugin.py` - daemon contract
4. `api/services/plugin/plugin_service.py` - install/upgrade orchestration
5. `api/core/workflow/nodes/trigger_plugin/trigger_event_node.py` - workflow entry

## Notes for plugin authors

- Dify treats plugin providers (tool/model/datasource/trigger/endpoint/agent strategy) uniformly; the adapters live under `api/core/plugin/impl/`.
- The daemon is a separate service; see `skills/dify-plugin/references/dify-plugin-daemon.md` for runtime behavior and CLI.
- The plugin skill expects you to mirror this structure when you reason about manifests and runtime behavior.
