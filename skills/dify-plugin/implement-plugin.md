# Implement Plugin

Use this guide after the plugin plan and local environment are ready. It links the key docs in this folder so the LLM can pull the right context at each step.

## Reading Order (Required)

1. [architecture.md](references/architecture.md) - runtime types, lifecycle, and hooks
2. [manifest.md](references/manifest.md) - full manifest rules and validation
3. [credentials.md](references/credentials.md) - credential schema and validation rules
4. [yaml-schemas.md](references/yaml-schemas.md) - YAML patterns for credentials/params
5. [security.md](references/security.md) - baseline security checklist
5. Category guide that matches your plugin type:
   - [tool-plugin.md](plugin-guide-by-category/tool-plugin.md)
   - [model-plugin.md](plugin-guide-by-category/model-plugin.md)
   - [trigger-plugin.md](plugin-guide-by-category/trigger-plugin.md)
   - [datasource-plugin.md](plugin-guide-by-category/datasource-plugin.md)
   - [extension-plugin.md](plugin-guide-by-category/extension-plugin.md)
   - [agent-strategy-plugin.md](plugin-guide-by-category/agent-strategy-plugin.md)

## Implementation Checklist

1. Confirm plugin category and pick the correct guide (above).
2. Draft `manifest.yaml` using [manifest.md](references/manifest.md).
3. Define provider config YAML:
   - Use [credentials.md](references/credentials.md) for credential rules
   - Use [yaml-schemas.md](references/yaml-schemas.md) for YAML patterns
   - Place files in the directory structure for your category guide
4. Implement provider validation and runtime logic in `provider/*.py`.
5. Implement tool/event/model/datasource/endpoint code in its directory.
6. Validate error handling style with [common-issues-and-check.md](common-issues-and-check.md).

## Reference Repos (When You Need Examples)

- [dify-official-plugins](references/dify-official-plugins.md) - real plugin structures
- [dify-plugin-sdk](references/dify-plugin-sdk.md) - SDK interfaces and runtime APIs
- [dify-plugin-daemon](references/dify-plugin-daemon.md) - runtime behavior and CLI
