# Dify Plugin SDK

Use this repository to understand the SDK surface area used by plugin authors, including runtime sessions, provider interfaces, and example plugins.

Repo: [langgenius/dify-plugin-sdks](https://github.com/langgenius/dify-plugin-sdks)

## Why it matters for this skill

- Defines the SDK interfaces that your plugin code implements.
- Shows how runtime sessions and backwards invocation work in Python.
- Provides runnable examples for tools, models, triggers, and agents.

## Repo structure

- `python/` - primary SDK implementation
- `python/examples/` - plugin examples (tools, triggers, agents, datasources)
- `python/README.md` - SDK versioning guidance for plugin projects

## Core SDK architecture (Python)

From `CLAUDE.md`:

- `python/dify_plugin/core/runtime.py` - session management and backwards invocation
- `python/dify_plugin/core/plugin_executor.py` - main execution engine
- `python/dify_plugin/core/plugin_registration.py` - plugin discovery and registration
- `python/dify_plugin/core/server/` - stdio, TCP, serverless communication layers

## Plugin interfaces

The SDK exposes provider interfaces under `python/dify_plugin/interfaces/`:

- `model/` - LLM, embedding, TTS, rerank, etc.
- `tool/` - tool providers and actions
- `agent/` - agent strategies
- `endpoint/` - HTTP endpoint handlers
- `trigger/` - trigger event handlers

## Example layout

Most examples in `python/examples/` follow a consistent structure:

- `manifest.yaml` - plugin metadata and runtime constraints
- `main.py` - plugin entry point
- `provider/` - provider config and implementation
- `tools/` or `models/` - concrete operations
- `requirements.txt` - plugin dependencies

## Version compatibility

The root `README.md` documents how `meta.version` and `meta.minimum_dify_version` are used to ensure compatibility between plugin packages and Dify runtime versions.

Use these tables to decide when to bump manifest versions or require a newer Dify release.

## Suggested reading order

1. `README.md` - manifest versioning rules
2. `python/README.md` - SDK version constraints for plugins
3. `CLAUDE.md` - architecture map and core components
4. `python/examples/` - pick a plugin type close to your use case
