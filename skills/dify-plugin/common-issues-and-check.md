## When Stuck: Where to Look

| Problem | Solution |
|---------|----------|
| manifest.yaml validation error | [manifest.md](./implement-plugin/manifest.md) |
| How to structure YAML files | [yaml-schemas.md](./implement-plugin/yaml-schemas.md) + [dify-official-plugins](./references/dify-official-plugins.md) |
| Python interface/method signature | [dify-plugin-sdk](./references/dify-plugin-sdk.md) |
| Runtime behavior, hooks | [architecture.md](./implement-plugin/architecture.md) |
| Error handling patterns | [Error Handling](#2-error-handling) |
| Working examples | [dify-official-plugins](./references/dify-official-plugins.md) |

# Dify Plugin Development Best Practices

This document summarizes common principles and pitfalls in Dify plugin development.

## Table of Contents

1. [Execution Status Mechanism](#1-execution-status-mechanism)
2. [Error Handling](#2-error-handling)
3. [HTTP Requests](#3-http-requests)
4. [Message Returns](#4-message-returns)
5. [Performance & Resources](#5-performance--resources)
6. [Logging](#6-logging)

---

## 1. Execution Status Mechanism

### 1.1 Core Principle

Plugin execution status is determined by **Session Message Type**, not by the content returned:

| Message Type | Execution Status | Trigger Condition |
|---|---|---|
| `SESSION_MESSAGE_TYPE_STREAM` | In Progress | Normal yield message |
| `SESSION_MESSAGE_TYPE_END` | **SUCCESS** | Function ends normally |
| `SESSION_MESSAGE_TYPE_ERROR` | **FAILURE** | Exception raised |

### 1.2 Common Mistake

**Wrong example**: The following code shows SUCCESS even when API returns 404

```python
def _invoke(self, tool_parameters: dict[str, Any]):
    response = httpx.get(url, headers=headers)

    if response.status_code == 404:
        # ❌ This only returns a text message, doesn't make status FAILURE
        yield self.create_text_message("Resource not found")
        return

    yield self.create_json_message(response.json())
```

**Reason**: `create_text_message` just creates a text message (STREAM type), function ends normally and sends END, so status is SUCCESS.

### 1.3 Correct Approach

To make execution status show as FAILURE, you must **raise an exception**:

```python
def _invoke(self, tool_parameters: dict[str, Any]):
    response = httpx.get(url, headers=headers)

    if response.status_code == 404:
        # ✅ Raise exception, execution status becomes FAILURE
        raise ValueError("Resource not found")

    if response.status_code == 401:
        # ✅ Use dedicated exception type
        raise ToolProviderCredentialValidationError("Authentication failed")

    yield self.create_json_message(response.json())
```

### 1.4 Status Determination Summary

| Code Behavior | Session Message | Execution Status |
|---|---|---|
| `yield self.create_text_message(...)` + normal end | STREAM → END | SUCCESS |
| `yield self.create_json_message(...)` + normal end | STREAM → END | SUCCESS |
| `raise Exception(...)` | ERROR | FAILURE |
| `raise ValueError(...)` | ERROR | FAILURE |
| `raise ToolProviderCredentialValidationError(...)` | ERROR | FAILURE |

### 1.5 When to Use Message vs Exception

| Scenario | Recommended Approach | Example |
|---|---|---|
| Business logic succeeds, empty result | `create_text_message` | "No results found for your query" |
| Missing or invalid parameters | `raise ValueError` | Required parameter missing |
| API returns 4xx/5xx | `raise Exception` | Resource not found, permission denied |
| Invalid credentials | `raise ToolProviderCredentialValidationError` | API Key expired |
| Network error | `raise Exception` or let it bubble up | Connection timeout |

---

## 2. Error Handling

### 2.1 Exception Types

```python
from dify_plugin.errors.tool import (
    ToolProviderCredentialValidationError,  # Credential validation failed
    ToolInvokeError,                         # Tool invocation failed
)
```

### 2.2 Recommended Pattern

```python
def _invoke(self, tool_parameters: dict[str, Any]):
    # 1. Parameter validation
    query = tool_parameters.get("query")
    if not query:
        raise ValueError("query is required")

    # 2. Credential retrieval
    api_key = self.runtime.credentials.get("api_key")
    if not api_key:
        raise ToolProviderCredentialValidationError("API Key is required")

    # 3. API call
    try:
        response = httpx.get(url, headers=headers, timeout=30)

        # 4. HTTP status code handling
        if response.status_code == 401:
            raise ToolProviderCredentialValidationError("Invalid API Key")
        elif response.status_code == 404:
            raise ValueError(f"Resource '{resource_id}' not found")
        elif response.status_code >= 400:
            raise Exception(f"API error: {response.status_code} - {response.text}")

        # 5. Success return
        yield self.create_json_message(response.json())

    except httpx.TimeoutException:
        raise Exception("Request timeout, please try again")
    except httpx.HTTPError as e:
        raise Exception(f"Network error: {str(e)}")
```

### 2.3 Provider Credential Validation

```python
class MyProvider(ToolProvider):
    def _validate_credentials(self, credentials: dict) -> None:
        api_key = credentials.get("api_key")
        if not api_key:
            raise ToolProviderCredentialValidationError("API Key is required")

        # Call API to validate credentials
        try:
            response = httpx.get(
                "https://api.example.com/me",
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=10
            )
            if response.status_code == 401:
                raise ToolProviderCredentialValidationError("Invalid API Key")
            response.raise_for_status()
        except httpx.HTTPError as e:
            raise ToolProviderCredentialValidationError(f"Failed to validate: {e}")
```

---

## 3. HTTP Requests

### 3.1 Always Set Timeout

```python
# ✅ Correct
response = httpx.get(url, timeout=30)

# ❌ Wrong - may wait indefinitely
response = httpx.get(url)
```

### 3.2 Recommended Timeout Values

| Scenario | Timeout |
|---|---|
| Normal API calls | 30 seconds |
| Credential validation | 10 seconds |
| File downloads | 60-120 seconds |
| Long-running API | 120 seconds |

### 3.3 Use httpx

Prefer `httpx` over `requests`:

```python
import httpx

# Synchronous requests
response = httpx.get(url, headers=headers, timeout=30)
response = httpx.post(url, json=data, headers=headers, timeout=30)

# Check status
response.raise_for_status()  # Raises exception for 4xx/5xx
```

---

## 4. Message Returns

### 4.1 Message Type Selection

| Data Type | Recommended Method | Example |
|---|---|---|
| Structured data | `create_json_message` | API response, list data |
| Plain text | `create_text_message` | Prompts, simple results |
| Links | `create_link_message` | URL |
| Binary | `create_blob_message` | Images, files |

### 4.2 Prefer JSON

```python
# ✅ Recommended - structured data
yield self.create_json_message({
    "status": "success",
    "data": {"id": "123", "name": "Example"},
    "count": 1
})

# ⚠️ Not recommended - passing structured data as text
yield self.create_text_message('{"status": "success", ...}')
```

### 4.3 Multiple Message Returns

```python
def _invoke(self, tool_parameters: dict[str, Any]):
    # Can yield multiple messages
    yield self.create_text_message("Processing started...")

    result = self._process_data()
    yield self.create_json_message(result)

    yield self.create_text_message("Processing completed.")
```

---

## 5. Performance & Resources

### 5.1 Avoid LLM Abuse

```python
# ❌ Wrong - don't use LLM for simple formatting
def _invoke(self, tool_parameters: dict[str, Any]):
    data = self._fetch_data()
    # Don't use LLM to format JSON
    formatted = self.session.model.invoke("Format this as markdown: " + str(data))
    yield self.create_text_message(formatted)

# ✅ Correct - return data directly
def _invoke(self, tool_parameters: dict[str, Any]):
    data = self._fetch_data()
    yield self.create_json_message(data)
```

### 5.2 Set Memory Appropriately

```yaml
# manifest.yaml
resource:
  memory: 268435456  # 256MB, sufficient for typical tools
```

| Plugin Type | Recommended Memory |
|---|---|
| Simple API calls | 128-256 MB |
| Data processing | 256-512 MB |
| File processing | 512 MB - 1 GB |

### 5.3 Single Responsibility

- One plugin per API service
- One Tool per operation
- Avoid implementing multiple features in a single Tool

---

## 6. Logging

For complete logging documentation, see [logging.md](references/logging.md).

### 6.1 Required Setup

Every Python file with business logic must configure logging with DEBUG mode control:

```python
import os
import logging
from dify_plugin.config.logger_format import plugin_logger_handler

DEBUG_MODE = os.getenv("DEBUG", "false").lower() == "true"

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG if DEBUG_MODE else logging.INFO)
logger.addHandler(plugin_logger_handler)
```

### 6.2 Debug vs Production Logging

| Mode | What to Log | What NOT to Log |
|------|-------------|-----------------|
| **Debug** (`DEBUG=true`) | Verbose info, masked params, response structure | Still no raw credentials |
| **Production** (`DEBUG=false`) | Key operations, errors, status codes | **NEVER: credentials, PII, request/response bodies** |

### 6.3 Security: Never Log Sensitive Data in Production

> **CRITICAL**: Production log violations are security incidents.

```python
# ❌ FORBIDDEN in production
logger.info(f"API key: {api_key}")
logger.info(f"Headers: {headers}")
logger.info(f"User email: {user_email}")
logger.info(f"Request body: {body}")
logger.info(f"Response: {response.text}")

# ✅ SAFE for production
logger.info("API key configured: yes")
logger.info(f"Calling: {url}")
logger.info(f"Response status: {status_code}")
logger.info(f"Processing request (user_id={user_id})")

# ✅ SAFE - verbose logging in debug mode only
if DEBUG_MODE:
    logger.debug(f"Params: {safe_log_params(params)}")
    logger.debug(f"Response keys: {list(result.keys())}")
```

### 6.4 Log Destinations

| Environment | Where Logs Appear |
|-------------|-------------------|
| Remote Debug | Terminal running `python -m main` |
| Production | Plugin daemon container logs |

---

## Appendix: FAQ

### Q: Why does API return error but execution status is SUCCESS?

A: Because you used `yield self.create_text_message(error)` to return the error message instead of raising an exception. Function ending normally = SUCCESS. Use `raise Exception(error)` or `raise ValueError(error)` instead.

### Q: When should I use `create_text_message` to return errors?

A: When the error is a **normal business situation**, like "no search results", "user has no orders". These are not real errors, just empty results.

### Q: What's the difference between Provider validation and Tool invocation error handling?

A: Provider validation (`_validate_credentials`) failure prevents users from saving credentials. Tool invocation (`_invoke`) failure only affects a single execution. Both should raise exceptions to indicate failure.

## Common Pitfalls

### ❌ Don't:
1. Use LLM calls in tools for simple data formatting
2. Use `httpx.RequestException` (doesn't exist)
3. Hardcode API URLs without environment selection
4. Mix different APIs in one plugin
5. Use invalid tags (e.g., "banking", "payments")
6. Request unnecessary permissions (e.g., model permission when not using LLM)
7. Log sensitive data (API keys, passwords, tokens, PII)
8. Use `print()` for logging - use proper logger instead

### ✅ Do:
1. Return structured JSON data directly
2. Use `httpx.HTTPError` for exception handling
3. Support multiple environments (Sandbox/Production)
4. Separate concerns (one plugin per API service)
5. Use official tags (finance, utilities, productivity)
6. Test thoroughly before release
7. Use `plugin_logger_handler` for all logging
8. Log errors with context using `logger.exception()`
