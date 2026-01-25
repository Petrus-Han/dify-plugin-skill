# Quick Start: Running Dify Plugins Locally

This guide provides the fastest way to get started with running and testing Dify plugins locally using the `dify` CLI in JSON mode.


## Dify CLI Examples

The following command will start a plugin in standard I/O (stdio) mode with JSON response format:

**This command will always wait for stdin. Please be careful of deadlocks.**

```bash
dify plugin run plugin.difypkg -m stdio -r json
```

For testing purposes, please see [code-examples.md](./code-examples.md).

## Dify CLI Syntax

### Parameters

```bash
dify plugin run <plugin.difypkg> [options]
```

| Option | Short | Default | Description |
|------|-----|--------|------|
| `--mode` | `-m` | `stdio` | Execution mode: `stdio` or `tcp` |
| `--enable-logs` | `-l` | `false` | Enable detailed debug logs |
| `--response-format` | `-r` | `text` | Response format: `text` or `json` (JSON is recommended for automation) |

### Interaction

The plugin will wait for stdin and respond with stdout.
The interaction format is available in [protocol-spec.md](./protocol-spec.md).

## Troubleshooting

For common issues and solutions, please refer to [troubleshooting.md](./troubleshooting.md).