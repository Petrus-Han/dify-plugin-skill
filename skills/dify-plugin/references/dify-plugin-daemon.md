# Dify Plugin Daemon

Use this repository to understand how plugins are executed, packaged, and debugged at runtime.

Repo: [langgenius/dify-plugin-daemon](https://github.com/langgenius/dify-plugin-daemon)

## Why it matters for this skill

- It is the runtime that Dify calls to install, launch, and invoke plugins.
- The CLI used for local plugin development lives here.
- Runtime types (local, debug, serverless) define how your plugin is executed.

## Runtime overview

The daemon supports three execution modes:

1. Local runtime (subprocess, STDIN/STDOUT)
2. Debug runtime (TCP, plugin connects back)
3. Serverless runtime (HTTP, via SRI)

See `README.md` and `docs/runtime/sri.md` for the high-level behavior and serverless protocol.

## Key directories

- `cmd/server/main.go` - daemon entrypoint and config bootstrap
- `internal/server/server.go` - server initialization, storage, plugin manager, cluster
- `internal/types/app/config.go` - environment variables and runtime configuration
- `internal/core/plugin_manager/` - lifecycle and runtime coordination
- `internal/core/control_panel/` - launch and watchdog logic for local/debug runtimes
- `internal/core/plugin_daemon/` - invocation orchestration and session flow

## CLI for plugin development

- `cmd/commandline/main.go` - CLI root (`dify`)
- `cmd/commandline/run.go` - `dify plugin run <path>` (stdio or tcp)
- `cmd/commandline/plugin/` - plugin init/package helpers
- `cmd/commandline/bundle/` - bundle packaging
- `cmd/commandline/signature/` - sign/verify difypkg

## Config highlights

- Plugin working/install paths and package cache
- Runtime buffers and max execution timeout
- UV and Python interpreter path for Python plugins
- Storage backend (local, S3, OSS, etc.)

Start with `internal/types/app/config.go` to see the full env surface area.

## Serverless Runtime Interface (SRI)

`docs/runtime/sri.md` documents the HTTP contract the daemon uses to launch serverless plugins:

- `GET /ping` health check
- `GET /v1/runner/instances` list ready instances by plugin package name
- `POST /v1/launch` launch with SSE progress events

This is essential if you are building or hosting a serverless runtime.

## How it connects to Dify

- Dify calls the daemon via HTTP; see `api/core/plugin/impl/base.py` and `api/core/plugin/impl/plugin.py` in the Dify repo.
- The daemon routes calls to the correct runtime (local/debug/serverless) and streams responses back.

## Suggested reading order

1. `README.md` - overview and runtime types
2. `CLAUDE.md` - architecture map and CLI notes
3. `internal/types/app/config.go` - configuration surface
4. `docs/runtime/sri.md` - serverless protocol
