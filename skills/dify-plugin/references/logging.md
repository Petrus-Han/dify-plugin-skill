# Plugin Logging

This guide covers how to add logging to Dify plugins for development debugging and production compliance.

## Security First Principle

> **CRITICAL**: Never log sensitive information in production. This includes API keys, passwords, tokens, PII (emails, phone numbers, names), request/response bodies containing user data.

## Quick Start

```python
import os
import logging
from dify_plugin.config.logger_format import plugin_logger_handler

# Environment-based log level control
DEBUG_MODE = os.getenv("DEBUG", "false").lower() == "true"

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG if DEBUG_MODE else logging.INFO)
logger.addHandler(plugin_logger_handler)
```

## Debug vs Production Mode

| Aspect | Debug Mode (`DEBUG=true`) | Production Mode |
|--------|---------------------------|-----------------|
| Log Level | DEBUG | INFO or WARNING |
| Verbose details | Yes | No |
| Parameter values | Safe to log | **NEVER log sensitive values** |
| Request/Response bodies | Safe to log | **NEVER log** |
| Stack traces | Full | Summarized |

### Environment Control

```python
import os

DEBUG_MODE = os.getenv("DEBUG", "false").lower() == "true"
```

Set in `.env` file:
```bash
# Development
DEBUG=true

# Production
DEBUG=false
```

## Log Output Destinations

| Environment | Output Location |
|-------------|-----------------|
| Remote Debugging | Local terminal stdout (where `python -m main` runs) |
| Production | Plugin daemon container logs (Community Edition only) |

## Logging Methods

```python
logger.debug("Detailed diagnostic info")    # Only shown in DEBUG mode
logger.info("Normal operation info")         # General information
logger.warning("Warning conditions")         # Potential issues
logger.error("Error conditions")             # Errors that need attention
logger.exception("Error with traceback")     # Includes stack trace
```

## Complete Example

```python
import os
import logging
from dify_plugin.config.logger_format import plugin_logger_handler
from dify_plugin import Tool
from dify_plugin.entities.tool import ToolInvokeMessage
from collections.abc import Generator
from typing import Any
import httpx

# Environment-based debug control
DEBUG_MODE = os.getenv("DEBUG", "false").lower() == "true"

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG if DEBUG_MODE else logging.INFO)
logger.addHandler(plugin_logger_handler)


def safe_log_params(params: dict) -> dict:
    """Mask sensitive parameters for safe logging."""
    sensitive_keys = {"api_key", "password", "token", "secret", "credential", "auth"}
    return {
        k: "***MASKED***" if any(s in k.lower() for s in sensitive_keys) else v
        for k, v in params.items()
    }


class MyTool(Tool):
    def _invoke(self, tool_parameters: dict[str, Any]) -> Generator[ToolInvokeMessage]:
        query = tool_parameters.get("query")

        # Debug mode: log full params (safe ones only)
        if DEBUG_MODE:
            logger.debug(f"Tool params: {safe_log_params(tool_parameters)}")

        # Production: only log operation start
        logger.info("Tool invoked")

        try:
            response = httpx.get(
                "https://api.example.com/search",
                params={"q": query},
                timeout=30
            )
            logger.info(f"API response status: {response.status_code}")

            if response.status_code >= 400:
                # Never log response body in production - may contain sensitive data
                logger.error(f"API error: {response.status_code}")
                if DEBUG_MODE:
                    logger.debug(f"Error response: {response.text[:500]}")
                raise Exception(f"API error: {response.status_code}")

            result = response.json()
            logger.info(f"Retrieved {len(result.get('items', []))} items")

            # Debug mode: log response structure
            if DEBUG_MODE:
                logger.debug(f"Response keys: {list(result.keys())}")

            yield self.create_json_message(result)

        except httpx.TimeoutException:
            logger.error("Request timeout")
            raise
        except Exception as e:
            # Log exception without exposing sensitive details
            logger.exception("Unexpected error during API call")
            raise
```

## Logging Best Practices

### 1. What to Log (Development)

During development, log generously to understand plugin behavior:

```python
# Entry/exit points
logger.info(f"Starting tool with params: {tool_parameters}")
logger.info("Tool completed successfully")

# API interactions
logger.info(f"Calling API: {url}")
logger.info(f"Response status: {response.status_code}")

# Data processing
logger.debug(f"Processing {len(items)} items")
logger.debug(f"Transformed data: {result}")
```

### 2. What to Log (Production)

In production, focus on actionable information:

| Log Level | When to Use | Example |
|-----------|-------------|---------|
| INFO | Key operations | "Tool invoked", "API call completed" |
| WARNING | Recoverable issues | "Rate limited, retrying", "Using fallback" |
| ERROR | Failures | "API returned 500", "Invalid response format" |

### 3. What NOT to Log (Production)

> **CRITICAL SECURITY RULE**: Never log sensitive information in production logs.

#### Forbidden in Production Logs

| Category | Examples | Why |
|----------|----------|-----|
| Credentials | API keys, passwords, tokens, secrets | Security breach risk |
| Auth Headers | `Authorization`, `X-API-Key` headers | Credential exposure |
| PII | Email, phone, name, address | Privacy/GDPR compliance |
| Request Bodies | Full POST/PUT payloads | May contain sensitive data |
| Response Bodies | Full API responses | May contain user data |

#### Code Examples

```python
# ❌ FORBIDDEN in production - exposes credentials
logger.info(f"Using API key: {api_key}")
logger.info(f"Headers: {headers}")
logger.info(f"Token: {token}")

# ❌ FORBIDDEN in production - exposes user data
logger.info(f"User email: {user_email}")
logger.info(f"Request body: {request_body}")
logger.info(f"Response: {response.text}")

# ✅ SAFE for production
logger.info("API key configured: yes")
logger.info(f"Request to: {url}")
logger.info(f"Response status: {response.status_code}")
logger.info(f"Processing request (user_id={user_id})")

# ✅ SAFE - use masking helper for debug mode only
if DEBUG_MODE:
    logger.debug(f"Params: {safe_log_params(params)}")
```

#### Masking Helper Function

Always use this helper when logging parameters:

```python
def safe_log_params(params: dict) -> dict:
    """Mask sensitive parameters for safe logging. Use only in DEBUG mode."""
    sensitive_keys = {
        "api_key", "password", "token", "secret", "credential",
        "auth", "key", "bearer", "email", "phone"
    }
    return {
        k: "***MASKED***" if any(s in k.lower() for s in sensitive_keys) else v
        for k, v in params.items()
    }
```

### 4. Log Level Guidelines

```python
# Set appropriate level based on environment
import os

log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logger.setLevel(getattr(logging, log_level, logging.INFO))
```

| Environment | Recommended Level |
|-------------|-------------------|
| Development/Debug | DEBUG |
| Staging | INFO |
| Production | INFO or WARNING |

## Provider Logging Example

```python
import os
import logging
import httpx
from dify_plugin.config.logger_format import plugin_logger_handler
from dify_plugin import ToolProvider
from dify_plugin.errors.tool import ToolProviderCredentialValidationError

DEBUG_MODE = os.getenv("DEBUG", "false").lower() == "true"

logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG if DEBUG_MODE else logging.INFO)
logger.addHandler(plugin_logger_handler)


class MyProvider(ToolProvider):
    def _validate_credentials(self, credentials: dict) -> None:
        logger.info("Validating provider credentials")

        # Debug mode: log which credential keys are present (NOT values!)
        if DEBUG_MODE:
            logger.debug(f"Credential keys provided: {list(credentials.keys())}")

        api_key = credentials.get("api_key")
        if not api_key:
            logger.warning("Credential validation failed: missing API key")
            raise ToolProviderCredentialValidationError("API Key is required")

        # NEVER log the actual api_key value
        logger.info("API key provided, validating with remote service")

        try:
            response = httpx.get(
                "https://api.example.com/validate",
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=10
            )

            if response.status_code == 401:
                logger.warning("Credential validation failed: invalid API key")
                raise ToolProviderCredentialValidationError("Invalid API Key")

            logger.info("Credentials validated successfully")

        except httpx.HTTPError as e:
            # Log error type, not full exception which may contain sensitive data
            logger.error(f"Credential validation error: {type(e).__name__}")
            if DEBUG_MODE:
                logger.debug(f"Full error: {e}")
            raise ToolProviderCredentialValidationError(f"Validation failed: {type(e).__name__}")
```

## Debugging Tips

### Viewing Logs During Remote Debug

1. Start your plugin: `python -m main`
2. Logs appear in the terminal where the command runs
3. Use DEBUG level for maximum visibility:
   ```python
   logger.setLevel(logging.DEBUG)
   ```

### Viewing Production Logs (Community Edition)

```bash
# View plugin daemon logs
docker logs dify-plugin-daemon

# Follow logs in real-time
docker logs -f dify-plugin-daemon

# Filter by plugin name (if using structured logging)
docker logs dify-plugin-daemon 2>&1 | grep "my_plugin"
```

## Checklist

### Before Submitting a Plugin

#### Required Setup
- [ ] All Python files import `plugin_logger_handler` and configure logger
- [ ] `DEBUG_MODE` environment variable controls log level
- [ ] `safe_log_params()` helper function implemented

#### Security (MANDATORY)
- [ ] **NO credentials in logs** (API keys, passwords, tokens, secrets)
- [ ] **NO auth headers in logs** (Authorization, X-API-Key, Bearer)
- [ ] **NO PII in logs** (email, phone, name, address)
- [ ] **NO request/response bodies in production logs**
- [ ] Sensitive params masked using `safe_log_params()` in DEBUG mode only

#### Best Practices
- [ ] Key operations logged at INFO level
- [ ] Errors logged at ERROR level with context
- [ ] Use `logger.exception()` for exception logging
- [ ] Verbose logging wrapped in `if DEBUG_MODE:` blocks
- [ ] Log messages are clear and actionable

### Code Review Checklist

When reviewing plugin code, reject if:
1. Any `logger.*` call contains credential variables directly
2. Any `logger.*` call logs full request/response bodies without DEBUG check
3. Missing `DEBUG_MODE` environment control
4. Using `print()` instead of logger
