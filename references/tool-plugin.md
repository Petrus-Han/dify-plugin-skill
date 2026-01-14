# Tool Plugin Development

Tool plugins add new capabilities to Dify workflows by integrating external APIs.

## Structure

```
my-tool/
├── provider/
│   ├── provider.yaml     # Provider + credentials config
│   └── provider.py       # Provider validation (optional)
├── tools/
│   ├── tool_name.yaml    # Tool definition
│   └── tool_name.py      # Tool implementation
├── manifest.yaml
├── main.py
└── requirements.txt
```

## provider.yaml

```yaml
identity:
  author: your-name
  name: my_provider
  label:
    en_US: My Provider
  description:
    en_US: Provider description
  icon: icon.svg

credentials_for_provider:
  api_key:
    type: secret-input
    required: true
    label:
      en_US: API Key
    placeholder:
      en_US: Enter your API key
    help:
      en_US: Get your API key from...
    url: https://example.com/api-keys

tools:
  - tools/my_tool.yaml

extra:
  python:
    source: provider/provider.py
```

## tool.yaml

```yaml
identity:
  name: my_tool
  author: your-name
  label:
    en_US: My Tool

description:
  human:
    en_US: Human-readable description
  llm: Description for LLM to understand when to use this tool

parameters:
  - name: query
    type: string
    required: true
    form: llm # llm = filled by LLM, form = user input
    label:
      en_US: Query
    human_description:
      en_US: Search query
    llm_description: The search query to execute

  - name: limit
    type: number
    required: false
    form: form
    default: 10
    label:
      en_US: Limit

extra:
  python:
    source: tools/my_tool.py
```

## Tool Implementation

```python
from collections.abc import Generator
from typing import Any

from dify_plugin import Tool
from dify_plugin.entities.tool import ToolInvokeMessage

class MyTool(Tool):
    def _invoke(
        self,
        tool_parameters: dict[str, Any]
    ) -> Generator[ToolInvokeMessage]:
        # Get parameters
        query = tool_parameters.get("query", "")

        # Get credentials
        api_key = self.runtime.credentials["api_key"]

        # Execute logic
        result = self._call_api(query, api_key)

        # Return results
        yield self.create_text_message(text=result)
        # Or: yield self.create_json_message(json={"key": "value"})

    def _call_api(self, query: str, api_key: str) -> str:
        # Implementation
        return "result"
```

## Parameter Types

| Type           | Description        |
| -------------- | ------------------ |
| `string`       | Text input         |
| `number`       | Numeric input      |
| `boolean`      | True/false toggle  |
| `select`       | Dropdown selection |
| `secret-input` | Encrypted input    |
| `file`         | Single file        |
| `files`        | Multiple files     |

## Message Types

```python
yield self.create_text_message(text="Hello")
yield self.create_json_message(json={"key": "value"})
yield self.create_link_message(link="https://...")
yield self.create_blob_message(blob=bytes, meta={"mime_type": "image/png"})
```

## Provider Validation (Optional)

```python
from dify_plugin import ToolProvider
from dify_plugin.errors.tool import ToolProviderCredentialValidationError

class MyProvider(ToolProvider):
    def _validate_credentials(self, credentials: dict) -> None:
        api_key = credentials.get("api_key")
        if not api_key:
            raise ToolProviderCredentialValidationError("API Key required")
        # Test the API key
```
