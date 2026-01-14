---
name: dify-plugin
description: Guide for creating Dify plugins (Tool, Trigger, Extension, Model, Datasource, Agent Strategy). Use when building integrations for Dify workflows, adding new tools, connecting external services via webhooks, or implementing custom model providers. Supports Python SDK with YAML configurations.
---

# Dify Plugin Development

Build plugins that extend Dify's capabilities through tools, triggers, extensions, models, and more.

## Quick Start

1. **Install Dify CLI**: `brew tap langgenius/dify && brew install dify` (or download from GitHub releases)
2. **Install uv**: `curl -LsSf https://astral.sh/uv/install.sh | sh`
3. **Init plugin**: `dify plugin init` (interactive) or `dify plugin init --quick --name my-plugin --category tool --language python`
4. **Setup dependencies**:
   ```bash
   cd my-plugin
   uv init --no-readme     # Initialize uv project
   uv add dify_plugin      # Add Dify SDK
   ```

## Development Workflow

Follow this structured process to build reliable Dify plugins:

### Phase 0: Pre-Planning 🔍

**0.1 Identify Plugin Type**
- Determine if you need Tool / Trigger / Model / Extension
- Choose based on the integration requirements

**0.2 Research Target API**
- Read official API documentation thoroughly
- Understand authentication methods (API Key / OAuth2)
- Note API rate limits and restrictions
- Check if there's a sandbox/test environment

**0.3 Check Official Examples**
- Search `dify-official-plugins` for similar integrations
- Review implementation patterns
- Identify reusable code structures

### Phase 1: Requirements Analysis ✅

**1.1 Define User Needs**
- What problem does this plugin solve?
- What workflows will it enable?

**1.2 Clarify Integration Goals**
- Which service are you integrating?
- What specific features are needed?

**1.3 Identify Authentication**
- API Token / OAuth2 / API Key?
- What scopes/permissions are required?

**1.4 Confirm Data Flow**
- Read-only queries?
- Write operations?
- Event-driven triggers?
- Bidirectional sync?

### Phase 2: Scope Definition 📋

**2.1 List All Tools**
- Define 3-7 tools for MVP
- Name them clearly (e.g., `get_accounts`, `create_charge`)

**2.2 Set Priorities**
- Mark essential tools for MVP
- Identify nice-to-have extensions

**2.3 Map Dependencies**
- Some tools depend on others (e.g., `create_token` → `create_charge`)
- Plan implementation order

**2.4 Evaluate Complexity**
- Simple: Single API call, basic parameters
- Medium: Multiple calls, data transformation
- Complex: OAuth flow, webhook verification, state management

**2.5 Note Limitations**
- API rate limits (e.g., 100 req/min)
- Geographic restrictions (e.g., US only)
- Environment constraints (e.g., no webhooks in sandbox)

### Phase 3: Planning & Approval 📝

**3.1 Create Task List**
- Use `TodoWrite` tool to track progress
- Break down into concrete tasks

**3.2 Document Key Files**
- `manifest.yaml` - Plugin metadata
- `provider.yaml` - Authentication config
- `provider.py` - OAuth/validation logic
- `tools/*.yaml` - Tool definitions
- `tools/*.py` - Tool implementations

**3.3 Identify Risks**
- Complex OAuth flows
- Undocumented API behaviors
- Missing test environments

**3.4 Get User Confirmation**
- Present plan clearly
- Use `AskUserQuestion` if choices needed

### Phase 4: Development 🔨

**4.1 Build Skeleton**
```bash
mkdir -p my_plugin/{_assets,provider,tools}
touch my_plugin/{manifest.yaml,main.py,requirements.txt}
touch my_plugin/provider/provider.{yaml,py}
```

**4.2 Implement Provider**
- Write `provider.yaml` with credentials schema
- Write `provider.py` with:
  - `_validate_credentials()` - Check token validity
  - `_oauth_get_authorization_url()` - Generate OAuth URL (if needed)
  - `_oauth_get_credentials()` - Exchange code for token (if needed)
  - `_oauth_refresh_credentials()` - Refresh expired tokens (if needed)
- Add helper methods (e.g., `get_api_base_url()`)

**4.3 Implement Tools**
- Implement in dependency order
- For each tool:
  1. Write `tools/{tool_name}.yaml` - Define parameters
  2. Write `tools/{tool_name}.py` - Implement logic
  3. Handle errors properly
  4. Return JSON data directly

**4.4 Code Review Checklist**
- [ ] No unnecessary LLM calls in tools
- [ ] Use `httpx.HTTPError` (not `RequestException`)
- [ ] Environment selection works correctly
- [ ] No hardcoded URLs or credentials
- [ ] Proper error messages for users
- [ ] Timeout values are reasonable (30s recommended)

### Phase 5: Credential Testing 🔑

**5.1 Setup Test Environment**
- Register developer account
- Create test application
- Choose Sandbox (if available) for initial testing

**5.2 Collect Credentials**
- Request test credentials from user
- Or guide user to obtain them
- Write diagnostic script (e.g., `test_api_key.py`)

**5.3 Validate Credentials**
```python
# Example diagnostic script
import httpx

def test_api_key(api_key, environment="sandbox"):
    url = "https://api-sandbox.example.com/v1/test"
    headers = {"Authorization": f"Bearer {api_key}"}
    response = httpx.get(url, headers=headers)
    print(f"Status: {response.status_code}")
    if response.status_code == 200:
        print("✅ API Key is valid!")
    else:
        print(f"❌ Error: {response.text}")
```

**5.4 Test Provider Validation**
```python
# Test _validate_credentials locally
from provider.my_provider import MyProvider

provider = MyProvider()
credentials = {"access_token": "test_token"}
try:
    provider._validate_credentials(credentials)
    print("✅ Provider validation passed")
except Exception as e:
    print(f"❌ Validation failed: {e}")
```

### Phase 6: End-to-End Testing 🧪

**6.1 Local Testing**
```python
# Create test script: test_local.py
import sys
sys.path.insert(0, "my_plugin")

from tools.get_data import GetDataTool

# Mock Dify runtime
class MockRuntime:
    def __init__(self, credentials):
        self.credentials = credentials

class MockSession:
    pass

# Test tool
runtime = MockRuntime({"access_token": "test_key"})
session = MockSession()
tool = GetDataTool(runtime=runtime, session=session)

results = list(tool._invoke({"param": "value"}))
print(f"Got {len(results)} messages")
for result in results:
    print(result)
```

**6.2 Package Testing**
```bash
dify plugin package ./my_plugin
# Check for errors
# Verify .difypkg size is reasonable
```

**6.3 Upload & Configure**
- Upload `.difypkg` to Dify
- Configure credentials in UI
- Test OAuth flow (if applicable)

**6.4 Tool Testing**
Test each tool systematically:
- ✅ Normal case: Valid inputs, successful response
- ❌ Error case: Invalid inputs, API errors
- 🔍 Edge case: Empty results, rate limits, timeouts

**6.5 Integration Testing**
- Create test workflow in Dify
- Chain multiple tools together
- Verify data passes correctly between tools
- Test error handling in workflow

### Phase 7: Documentation & Release 📚

**7.1 Write Documentation**
```markdown
# README.md
- Overview
- Features
- Authentication setup
- Usage examples
- Testing guide

# API_Documentation.md (if needed)
- Complete API reference
- All endpoints
- Parameters and responses
```

**7.2 Version Management**
```yaml
# Semantic Versioning: major.minor.patch
version: 0.1.0  # Initial release
version: 0.2.0  # New feature (backward compatible)
version: 0.2.1  # Bug fix
version: 1.0.0  # Breaking change
```

**7.3 Quality Checklist**
- [ ] `.gitignore` configured correctly
- [ ] No sensitive data in code
- [ ] Code comments are clear
- [ ] Error messages are helpful

**7.4 Final Package**
```bash
dify plugin package ./my_plugin
dify plugin checksum ./my_plugin.difypkg
# Share .difypkg with users
```

### Phase 8: Maintenance & Iteration 🔄

**8.1 Monitor Issues**
- Track user feedback
- Log common errors
- Identify improvement areas

**8.2 Add Features**
- New tools based on user needs
- Increment `minor` version (0.1.0 → 0.2.0)

**8.3 Fix Bugs**
- Quick fixes for critical issues
- Increment `patch` version (0.1.0 → 0.1.1)

---

## Common Pitfalls ⚠️

### ❌ DON'T:

1. **Use LLM in tools for simple formatting**
   ```python
   # ❌ BAD - Wastes tokens and adds latency
   yield self.create_text_message(
       self.session.model.summary.invoke(
           text=json.dumps(data),
           instruction="Format this nicely"
       )
   )

   # ✅ GOOD - Return JSON directly
   yield self.create_json_message(data)
   ```

2. **Use wrong exception types**
   ```python
   # ❌ BAD - httpx.RequestException doesn't exist
   except httpx.RequestException as e:
       pass

   # ✅ GOOD - Use httpx.HTTPError
   except httpx.HTTPError as e:
       pass
   ```

3. **Hardcode API URLs**
   ```python
   # ❌ BAD - No environment flexibility
   url = "https://api.example.com/v1/data"

   # ✅ GOOD - Support multiple environments
   env = self.runtime.credentials.get("environment", "production")
   url = f"https://api-{env}.example.com/v1/data"
   ```

4. **Mix different APIs in one plugin**
   - QuickBooks Accounting API ≠ QuickBooks Payments API
   - Create separate plugins for separate APIs

5. **Use invalid tags**

   Dify has strict tag validation. Only these 19 tags are valid:

   **Valid Tags:**
   - `search` - Search tools and services
   - `image` - Image generation, editing, analysis
   - `videos` - Video processing, creation
   - `weather` - Weather information services
   - `finance` - Financial services, banking, accounting
   - `design` - Design tools and services
   - `travel` - Travel and booking services
   - `social` - Social media integrations
   - `news` - News and RSS feeds
   - `medical` - Healthcare and medical services
   - `productivity` - Productivity and workflow tools
   - `education` - Educational tools and content
   - `business` - Business operations and CRM
   - `entertainment` - Entertainment and gaming
   - `utilities` - General utility tools
   - `agent` - Agent-related functionality
   - `rag` - RAG and knowledge base tools
   - `trigger` - Trigger/event plugins
   - `other` - Miscellaneous

   ```yaml
   # ❌ BAD - These tags don't exist
   tags:
     - banking      # Invalid! Use 'finance' instead
     - payments     # Invalid! Use 'finance' or 'utilities'
     - automation   # Invalid! Use 'productivity' or 'utilities'
     - api          # Invalid! Use appropriate category

   # ✅ GOOD - Use official tags only
   tags:
     - finance      # For financial/accounting plugins
     - utilities    # For general-purpose tools
     - productivity # For workflow/automation tools
   ```

6. **Request unnecessary permissions**
   ```yaml
   # ❌ BAD - Don't request model permission if not using LLM
   permission:
     tool:
       enabled: true
     model:
       enabled: true  # Only if actually using LLM!

   # ✅ GOOD - Request only what you need
   permission:
     tool:
       enabled: true
   ```

### ✅ DO:

1. **Return structured data**
   ```python
   # Tools should return clean JSON
   result = {
       "id": "123",
       "status": "success",
       "amount": 100.00
   }
   yield self.create_json_message(result)
   ```

2. **Handle errors gracefully**
   ```python
   if response.status_code == 401:
       yield self.create_text_message(
           "Authentication failed. Please check your API token."
       )
   elif response.status_code == 404:
       yield self.create_text_message(
           f"Resource '{resource_id}' not found."
       )
   ```

3. **Support multiple environments**
   ```python
   def get_api_url(self, credentials):
       env = credentials.get("environment", "sandbox")
       urls = {
           "sandbox": "https://api-sandbox.example.com",
           "production": "https://api.example.com"
       }
       return urls[env]
   ```

4. **Separate concerns**
   - One plugin per API service
   - One tool per operation
   - Clear, focused functionality

5. **Use official tag list**
   - finance
   - utilities
   - productivity
   - social
   - search
   - (check official plugins for complete list)

6. **Test thoroughly before release**
   - Local tests with mock runtime
   - Package validation
   - Manual testing in Dify
   - Test both success and error paths

---

## Debugging Guide 🐛

### Error: "permission denied, you need to enable llm access"

**Cause**: Tool is calling `self.session.model.summary.invoke()` but manifest doesn't have model permission.

**Solution**: Remove LLM calls from tools, return JSON directly.

### Error: "AttributeError: module 'httpx' has no attribute 'RequestException'"

**Cause**: Using non-existent exception type.

**Solution**: Change to `httpx.HTTPError`:
```python
except httpx.HTTPError as e:
    yield self.create_text_message(f"Network error: {e}")
```

### Error: "401 Unauthorized" in production

**Cause**: Using sandbox credentials in production environment.

**Solution**: Add environment selection to provider and use correct credentials for each environment.

### Error: "404 Not Found" on API calls

**Cause**: Wrong API base URL.

**Solution**: Verify API URL construction and environment selection logic.

### Tool returns empty data

**Cause**: API response structure changed or credentials lack permissions.

**Solution**:
1. Write diagnostic script to test API directly
2. Check API response structure
3. Verify credential scopes/permissions

### Error: "Field validation for 'Tags[X]' failed on the 'plugin_tag' tag"

**Cause**: Using invalid tag in manifest.yaml.

**Solution**: Use only the 19 valid tags (see Common Pitfalls #5):
```yaml
tags:
  - finance      # ✅ Valid
  - utilities    # ✅ Valid
  - banking      # ❌ Invalid - use 'finance' instead
  - payments     # ❌ Invalid - use 'finance' or 'utilities'
```

### Error: "Failed to parse response from plugin daemon"

**Cause**: YAML syntax error or tags defined in wrong location.

**Solution**:
- Ensure tags are only in `manifest.yaml`, NOT in `provider.yaml`
- Validate YAML syntax with a linter
- Check for duplicate keys or incorrect indentation

---

## Best Practices 💎

### Naming Conventions

```
Plugin Directory:    mercury_tools_plugin/
Plugin Name:         mercury_tools
Provider Files:      provider/mercury_tools.{yaml,py}
Tool Files:          tools/get_accounts.{yaml,py}
                     tools/create_charge.{yaml,py}
```

### Version Numbers

```yaml
0.1.0  # Initial release
0.2.0  # Added new tools (backward compatible)
0.2.1  # Fixed bug in get_accounts
1.0.0  # Changed API structure (breaking change)
```

### Security

- Never commit API keys or tokens
- Use OAuth2 when available
- Implement token refresh logic
- Validate all user inputs
- Use HTTPS for all API calls

### Performance

```python
# Set reasonable timeouts
response = httpx.get(url, timeout=30)

# Handle rate limiting
if response.status_code == 429:
    retry_after = response.headers.get("Retry-After")
    yield self.create_text_message(
        f"Rate limit exceeded. Retry after {retry_after}s"
    )

# Return only necessary data
result = {
    "id": data["id"],
    "name": data["name"]
    # Don't include huge nested objects unless needed
}
```

### Code Quality

```python
# Use type hints
def _invoke(self, tool_parameters: dict[str, Any]) -> Generator[ToolInvokeMessage, None, None]:
    pass

# Add docstrings
"""
Invoke the get_accounts tool to fetch all accounts.

Args:
    tool_parameters: Dictionary containing optional filters

Returns:
    Generator yielding account data as JSON
"""

# Keep functions focused
# Each tool does ONE thing well
```

---

## Real-World Examples 📚

### Example 1: Mercury Tools Plugin

**Features**:
- OAuth2 authentication
- Environment selection (Sandbox/Production)
- Three tools: get_accounts, get_account, get_transactions
- No LLM calls - pure JSON returns
- Proper exception handling

**Location**: `mercury_tools_plugin/`

### Example 2: QuickBooks Payments Plugin

**Features**:
- Separate from Accounting API
- Token-based payment processing
- Bank account management
- Refund capabilities

**Location**: `quickbooks_payments_plugin/`

### Example 3: Mercury Trigger Plugin

**Features**:
- Webhook receiver
- Signature verification
- Event filtering
- Automatic workflow triggering

**Location**: `mercury_trigger_plugin/`

---

## Plugin Types

| Type               | Purpose                       | Use When                                           |
| ------------------ | ----------------------------- | -------------------------------------------------- |
| **Tool**           | Add capabilities to workflows | Integrating external APIs (search, database, SaaS) |
| **Trigger**        | Start workflows from events   | Receiving webhooks (GitHub, Slack, custom)         |
| **Extension**      | Custom HTTP endpoints         | Building APIs, OAuth callbacks                     |
| **Model**          | New AI model providers        | Adding LLM/embedding providers                     |
| **Datasource**     | External data connections     | Connecting to databases, knowledge bases           |
| **Agent Strategy** | Custom agent logic            | Implementing specialized reasoning                 |

## Choose Your Plugin Type

- **Tool Plugin**: See [references/tool-plugin.md](references/tool-plugin.md)
- **Trigger Plugin**: See [references/trigger-plugin.md](references/trigger-plugin.md)
- **Extension Plugin**: See [references/extension-plugin.md](references/extension-plugin.md)
- **Model Plugin**: See [references/model-plugin.md](references/model-plugin.md)
- **YAML Schemas**: See [references/yaml-schemas.md](references/yaml-schemas.md)
- **Debugging & Deploy**: See [references/debugging.md](references/debugging.md)

## Core Structure

All plugins share this structure:

```
my-plugin/
├── _assets/icon.svg       # Plugin icon
├── provider/
│   ├── provider.yaml      # Provider config + credentials
│   └── provider.py        # Provider implementation
├── tools/ or events/      # Type-specific implementations
├── manifest.yaml          # Plugin metadata
├── main.py                # Entry point
├── pyproject.toml         # Dependencies (uv managed)
└── uv.lock                # Lock file (auto-generated)
```

## pyproject.toml Template

```toml
[project]
name = "my-plugin"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "dify_plugin>=0.1.0",
]

[tool.uv]
dev-dependencies = [
    "pytest>=8.0.0",
]
```

## Dependency Management

```bash
uv add <package>           # Add dependency
uv add -D <package>        # Add dev dependency
uv remove <package>        # Remove dependency
uv sync                    # Install all dependencies
uv lock                    # Update lock file
```

## manifest.yaml Template

```yaml
version: 0.1.0
type: plugin
author: your-name
name: my-plugin
created_at: "2025-01-01T00:00:00Z"
label:
  en_US: My Plugin
icon: icon.svg
description:
  en_US: Plugin description

resource:
  memory: 134217728
  permission:
    tool:
      enabled: true

plugins:
  tools: # or triggers/endpoints/models
    - provider/provider.yaml

tags:
  - finance      # Choose from 19 valid tags (see Common Pitfalls)
  - utilities

meta:
  version: 0.1.0
  arch: [amd64, arm64]
  runner:
    language: python
    version: "3.12"
    entrypoint: main
```

## main.py Template

```python
from dify_plugin import DifyPluginEnv, Plugin

plugin = Plugin(DifyPluginEnv())

if __name__ == "__main__":
    plugin.run()
```

## Remote Debugging

1. Get debug key from Dify console → Plugins → Remote Debugging
2. Create `.env`:
   ```
   INSTALL_METHOD=remote
   REMOTE_INSTALL_HOST=https://your-dify.com
   REMOTE_INSTALL_PORT=5003
   REMOTE_INSTALL_KEY=your-debug-key
   ```
3. Run with uv:
   ```bash
   uv run python -m main    # Run plugin with uv managed dependencies
   # or
   uv run main.py           # Alternative
   ```

## Package & Deploy

```bash
dify plugin package ./my-plugin          # Creates my-plugin.difypkg
dify plugin checksum ./my-plugin.difypkg # Verify package
```

## Official Plugin Examples

Reference: [github.com/langgenius/dify-official-plugins](https://github.com/langgenius/dify-official-plugins)

- **Tools**: arxiv, google_search, slack, github
- **Triggers**: github_trigger, slack_trigger, rsshub_trigger
- **Models**: openai, anthropic, google, azure_openai
