# Troubleshooting and Advanced Guides

This document covers message flow, environment configuration, performance optimization, and solutions to common issues.

---

## Message Flow Diagram

Understanding the sequence of messages is key to building a robust client.

```text
Startup Sequence:
  ↓ info (Loading)
  ↓ plugin_ready (Ready for requests)

Normal Request:
  ↓ info (Request received)
  ↓ plugin_response (Data payload - can be multiple)
  ↓ plugin_invoke_end (End of stream)

Error Case:
  ↓ error (Can occur at any stage)
```

---

## Performance Optimization

### Persistent Process
Avoid restarting the plugin for every request. Start the plugin once and keep the process running to reduce overhead.

### Pipelined Requests
The daemon supports processing multiple requests concurrently. Use unique `invoke_id` for each request and match them in the output stream.

### Handling Large Data
- **Streaming**: For large responses, the plugin sends multiple `plugin_response` messages. Process them as they arrive.
- **TCP Mode**: For very large payloads, TCP mode is generally more stable than STDIO.
- **Buffer Management**: Ensure your client reads from the output stream continuously to prevent the OS pipe buffer from filling up and blocking the plugin.

---

## Advanced Configuration

### Python Interpreter
Specify a specific Python version if the default `python3` is incorrect:
```bash
export PYTHON_INTERPRETER_PATH=/usr/bin/python3.11
```

### Logging
Use the `-l` or `--enable-logs` flag to see the plugin's internal stdout/stderr:
```bash
dify plugin run plugin.difypkg -m stdio -r json -l
```

---

## Common Issues and Solutions

| Issue | Symptom | Solution |
|-------|---------|----------|
| **JSON Error** | `unmarshal json failed` | Use double quotes for all keys and strings. Validate with `jq`. |
| **Missing Fields** | `action and type are required` | Ensure `invoke_id`, `type`, and `action` are at the root of your JSON. |
| **Startup Fail** | `no heartbeat received` | Check Python path and dependencies. Use `-l` for details. |
| **Timeout** | `execution timeout exceeded` | Break tasks into smaller chunks or increase timeout settings. |
| **Memory** | Process crashes on large data | Use TCP mode and streaming. |
| **TCP Refused** | `Connection refused` | Verify the host/port from the plugin's initial `info` message. |

---

## Quick Check-List

- [ ] JSON syntax is valid (no trailing commas, double quotes only).
- [ ] Every request has `invoke_id`, `type`, and `action`.
- [ ] Correct access type (e.g., `tool` vs `model`) is used.
- [ ] `PYTHON_INTERPRETER_PATH` is set if needed.
- [ ] `requirements.txt` in the plugin is valid.
- [ ] Client is reading until `plugin_invoke_end` is received.
- [ ] `-l` flag is enabled for deep debugging.
