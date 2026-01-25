# JSON Protocol Specification

Dify plugins communicate using a line-based JSON protocol. Each message is a single JSON object followed by a newline character (`\n`).

---

## Message Structure

### Output Message (Plugin to Client)

```json
{
  "invoke_id": "string",          // Request ID (empty for system/broadcast messages)
  "type": "string",               // Message type
  "response": {}                  // Data payload
}
```

### Message Types

| Type | Sent When | Response Content | Description |
|------|-----------|------------------|-------------|
| `info` | During processing | `{"info":"..."}` | Informational message |
| `plugin_ready` | After successful startup | `{"info":"..."}` | Plugin is ready to receive requests |
| `plugin_response` | During task execution | `{...}` | Actual data/result |
| `plugin_invoke_end` | Task completion | `{"info":"..."}` | End-of-stream marker |
| `error` | Any error occurs | `{"error":"..."}` | Error details |

---

## Request Format (Client to Plugin)

```json
{
  "invoke_id": "req-001",         // Required: Unique request identifier
  "type": "tool",                 // Required: Access type (tool, model, agent, etc.)
  "action": "invoke_tool",        // Required: Action name
  "request": {                    // Required: Action parameters
    "tool_name": "...",
    "..."
  }
}
```

---

## Standard Response Sequence

A successful interaction typically follows this sequence:

1.  `info`: Confirmation of request receipt.
2.  `plugin_response`: One or more data chunks.
3.  `plugin_invoke_end`: Final signal that the task is finished.

---

## Startup Phase

### Success Scenario
1.  `info`: "loading plugin"
2.  `plugin_ready`: "plugin loaded"

**Handling in Python:**
```python
proc.stdout.readline()  # Skip info
proc.stdout.readline()  # Skip plugin_ready
# Now safe to send requests
```

### Common Startup Errors

-   **File Error:** If the `.difypkg` is missing or corrupted.
    -   `{"invoke_id":"","type":"error","response":{"error":"read plugin file error: ..."}}`
-   **Manifest Error:** If `manifest.yaml` is missing or invalid.
    -   `{"invoke_id":"","type":"error","response":{"error":"get declaration error: ..."}}`
-   **Environment Error:** If the Python interpreter is not found.
    -   `{"invoke_id":"","type":"error","response":{"error":"initialize python environment error: ..."}}`
-   **Runtime Error:** If the plugin fails to start or heartbeat times out.
    -   `{"invoke_id":"","type":"error","response":{"error":"plugin runtime failed: ..."}}`

---

## TCP Mode Details

When running with `-m tcp`, the plugin acts as a server.

```bash
dify plugin run plugin.difypkg -m tcp -r json
```

On startup, it will output the binding information:
```json
{"invoke_id":"","type":"info","response":{"info":"plugin is running on 127.0.0.1:12345","host":"127.0.0.1","port":12345}}
```
Clients should connect to this host and port to begin communication.


## Types and Actions

### Access Types (`type`)
- `tool`: External tools and utilities.
- `model`: AI models (LLM, Embedding, Rerank, TTS, STT, etc.).
- `endpoint`: Custom API endpoints.
- `agent_strategy`: Specialized agent reasoning logic.
- `oauth`: OAuth2 authentication flows.
- `datasource`: Data connectors (Postgres, Google Drive, etc.).
- `dynamic_parameter`: Dynamic UI component options.
- `trigger`: Event triggers and webhooks.

---

## Detailed Action Catalog

### TOOL
- **`invoke_tool`**: Execute a tool.
- **`validate_tool_credentials`**: Verify tool-specific API keys.
- **`get_tool_runtime_parameters`**: Retrieve expected input parameters.

### MODEL (AI Models)
- **LLM**: `invoke_llm`, `get_llm_num_tokens`, `validate_provider_credentials`, `validate_model_credentials`, `get_ai_model_schemas`.
- **Embedding**: `invoke_text_embedding`, `get_text_embedding_num_tokens`, `invoke_multimodal_embedding`.
- **Rerank**: `invoke_rerank`, `invoke_multimodal_rerank`.
- **Speech**: `invoke_tts` (Text-to-Speech), `get_tts_model_voices`, `invoke_speech2text` (Speech-to-Text).
- **Moderation**: `invoke_moderation`.

### OAUTH
- **`get_authorization_url`**: Get the URL to redirect users for authorization.
- **`get_credentials`**: Exchange an auth code for access tokens.
- **`refresh_credentials`**: Refresh expired access tokens.

### DATASOURCE
- **`validate_datasource_credentials`**: Test connection to a database or service.
- **`invoke_online_drive_browse_files`**: List files in a cloud drive.
- **`invoke_online_drive_download_file`**: Get a download link for a file.
- **`invoke_website_datasource_get_crawl`**: Start a web crawl.

### TRIGGER
- **`invoke_trigger_event`**: Manually fire a trigger.
- **`subscribe_trigger`**: Register a webhook or subscription.
- **`unsubscribe_trigger`**: Remove a subscription.

---

## Example Payloads

### AGENT_STRATEGY Example
```json
{
  "invoke_id": "agent-001",
  "type": "agent_strategy",
  "action": "invoke_agent_strategy",
  "request": {
    "strategy_name": "react",
    "task": "solve 2+2",
    "context": {}
  }
}
```

### OAUTH Example (Get Auth URL)
```json
{
  "invoke_id": "oauth-1",
  "type": "oauth",
  "action": "get_authorization_url",
  "request": {
    "provider": "github",
    "redirect_uri": "https://myapp.com/callback"
  }
}
```

### DATASOURCE Example (Postgres)
```json
{
  "invoke_id": "ds-1",
  "type": "datasource",
  "action": "validate_datasource_credentials",
  "request": {
    "datasource_type": "postgres",
    "credentials": {
      "host": "localhost",
      "port": 5432,
      "database": "mydb",
      "username": "user"
    }
  }
}
```

---

## Error Handling

### Error Message Format
```json
{"invoke_id":"req-id","type":"error","response":{"error":"detailed error message"}}
```

### Common Error Codes

| Error Prefix | Cause | Solution |
|--------------|-------|----------|
| `decode plugin file error` | Invalid `.difypkg` | Ensure the file is a valid ZIP. |
| `get declaration error` | Missing `manifest.yaml` | Ensure `manifest.yaml` exists in the package root. |
| `initialize python environment error` | Python missing | Check `PYTHON_INTERPRETER_PATH`. |
| `plugin runtime failed` | Runtime crash/timeout | Check logs with `-l`. |
| `execution timeout exceeded` | Task took too long | Increase timeout or optimize plugin. |
| `unmarshal json failed` | Malformed JSON | Validate JSON syntax. |
