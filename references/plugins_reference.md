# Dify Official Plugins Reference

Reference guide for officially maintained plugins. Use this when developing new plugins to review existing implementations.

---

## Plugin Types Overview

| Type | Directory Prefix | Purpose |
|------|------------------|---------|
| Models | `models/` | LLM, Embedding, TTS provider integrations |
| Tools | `tools/` | External API and service integrations |
| Extensions | `extensions/` | Platform feature extensions |
| Triggers | `triggers/` | External event workflow triggers |
| Datasources | `datasources/` | External data source integrations |
| Agent Strategies | `agent-strategies/` | Agent reasoning strategies |

---

## Models

| Name | Directory | Description |
|------|-----------|-------------|
| openai | `models/openai` | OpenAI GPT series |
| anthropic | `models/anthropic` | Claude series |
| azure_openai | `models/azure_openai` | Azure OpenAI Service |
| deepseek | `models/deepseek` | DeepSeek models |
| zhipuai | `models/zhipuai` | Zhipu AI |
| tongyi | `models/tongyi` | Alibaba Tongyi Qianwen |
| siliconflow | `models/siliconflow` | SiliconFlow |
| vertex_ai | `models/vertex_ai` | Google Vertex AI |
| volcengine_maas | `models/volcengine_maas` | ByteDance Volcano Engine |
| cohere | `models/cohere` | Cohere models |

---

## Tools

| Name | Directory | Description |
|------|-----------|-------------|
| feishu_base | `tools/feishu_base` | Feishu Bitable |
| feishu_calendar | `tools/feishu_calendar` | Feishu Calendar |
| feishu_message | `tools/feishu_message` | Feishu Messaging |
| feishu_document | `tools/feishu_document` | Feishu Docs |
| e2b | `tools/e2b` | Code sandbox execution |
| lark_spreadsheet | `tools/lark_spreadsheet` | Lark Spreadsheet |
| lark_task | `tools/lark_task` | Lark Tasks |
| lark_message_and_group | `tools/lark_message_and_group` | Lark Messaging & Groups |
| lark_document | `tools/lark_document` | Lark Docs |
| wikipedia | `tools/wikipedia` | Wikipedia search |

---

## Extensions

| Name | Directory | Description |
|------|-----------|-------------|
| slack_bot | `extensions/slack_bot` | Slack Bot integration |
| openai_compatible | `extensions/openai_compatible` | OpenAI-compatible API endpoint |
| oaicompat_dify_model | `extensions/oaicompat_dify_model` | Dify model OpenAI compatibility layer |
| mcp_server | `extensions/mcp_server` | MCP server integration |
| wecom_bot | `extensions/wecom_bot` | WeCom Bot |
| llamacloud | `extensions/llamacloud` | LlamaCloud integration |
| badapple | `extensions/badapple` | Bad Apple demo |
| aws_bedrock_knowledge_base | `extensions/aws_bedrock_knowledge_base` | AWS Bedrock Knowledge Base |

---

## Triggers

| Name | Directory | Description |
|------|-----------|-------------|
| github_trigger | `triggers/github_trigger` | GitHub Webhook events |
| slack_trigger | `triggers/slack_trigger` | Slack events |
| lark_trigger | `triggers/lark_trigger` | Feishu/Lark events |
| linear_trigger | `triggers/linear_trigger` | Linear events |
| telegram_trigger | `triggers/telegram_trigger` | Telegram Bot messages |
| notion_trigger | `triggers/notion_trigger` | Notion change events |
| woocommerce_trigger | `triggers/woocommerce_trigger` | WooCommerce order events |
| zendesk_trigger | `triggers/zendesk_trigger` | Zendesk ticket events |
| gmail_trigger | `triggers/gmail_trigger` | Gmail events |
| outlook_trigger | `triggers/outlook_trigger` | Outlook email events |

---

## Datasources

| Name | Directory | Description | Provider Type | Auth Method |
|------|-----------|-------------|---------------|-------------|
| aws_s3_storage | `datasources/aws_s3_storage` | AWS S3 Storage - Access buckets and objects | `online_drive` | Access Key + Secret |
| azure_blob | `datasources/azure_blob` | Azure Blob Storage - Access containers and blobs with multiple auth methods | `online_drive` | Access Key / SAS Token / Connection String |
| github | `datasources/github` | GitHub Repository - Access repos, issues, PRs, and wiki pages | `online_document` | Personal Access Token / OAuth |
| google_drive | `datasources/google_drive` | Google Drive - Access files and folders | `online_drive` | OAuth |
| notion_datasource | `datasources/notion_datasource` | Notion - Access pages and databases | `online_document` | OAuth / Internal Integration Token |
| confluence_datasource | `datasources/confluence_datasource` | Confluence - Access spaces and pages | `online_document` | API Token / OAuth |
| dropbox_datasource | `datasources/dropbox_datasource` | Dropbox - Access files and folders | `online_drive` | OAuth / Access Token |
| firecrawl_datasource | `datasources/firecrawl_datasource` | Firecrawl - Web crawling and content extraction | `website_crawl` | API Key |
| jina_datasource | `datasources/jina_datasource` | Jina Reader - Web content extraction and parsing | `website_crawl` | API Key |
| onedrive | `datasources/onedrive` | OneDrive - Access files and folders | `online_drive` | OAuth |

### Datasource Implementation Examples

#### AWS S3 Storage (`datasources/aws_s3_storage`)
**Features:**
- Access S3 buckets and objects
- Region-based configuration
- Supports standard AWS authentication

**Credentials Schema:**
```yaml
credentials_schema:
  - name: secret_access_key
    type: secret-input
    required: true
  - name: access_key_id
    type: secret-input
    required: true
  - name: region_name
    type: text-input
    required: true
```

**Key Files:**
- `provider/aws_s3_storage.yaml` - Provider configuration
- `provider/aws_s3_storage.py` - AWS S3 client implementation
- `datasources/aws_s3_storage.yaml` - Datasource definition
- `datasources/aws_s3_storage.py` - Datasource logic

#### GitHub (`datasources/github`)
**Features:**
- Repository file access (public & private)
- Issues and Pull Requests with comments
- Multiple authentication methods (PAT / OAuth)
- Rate limit handling
- Automatic markdown processing

**Credentials Schema:**
```yaml
credentials_schema:
  - name: access_token
    type: secret-input
    required: true
    label:
      en_US: Personal Access Token
    url: https://github.com/settings/tokens

oauth_schema:
  client_schema:
    - name: client_id
      type: secret-input
    - name: client_secret
      type: secret-input
  credentials_schema:
    - name: access_token
      type: secret-input
    - name: refresh_token
      type: secret-input
```

**API Usage:**
- Base URL: `https://api.github.com`
- Rate Limits: 5,000 requests/hour
- Required Scopes: `repo`, `user:email`, `read:user`

**Key Implementation:**
```python
class GitHubDataSource(OnlineDocumentDatasource):
    def _get_headers(self) -> Dict[str, str]:
        access_token = self.runtime.credentials.get("access_token")
        return {
            "Authorization": f"token {access_token}",
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "Dify-GitHub-Datasource"
        }
```

#### Azure Blob Storage (`datasources/azure_blob`)
**Features:**
- Multiple authentication methods
- Container and blob access
- Comprehensive error handling

**Authentication Options:**
1. Access Key
2. SAS Token
3. Connection String

**Credentials Schema:**
```yaml
credentials_schema:
  - name: account_name
    type: text-input
    required: true
  - name: auth_method
    type: select
    options:
      - access_key
      - sas_token
      - connection_string
  - name: account_key
    type: secret-input
    required: false
```

#### Firecrawl (`datasources/firecrawl_datasource`)
**Features:**
- Web crawling and scraping
- Content extraction and cleaning
- Markdown conversion
- JavaScript rendering support

**Provider Type:** `website_crawl`

**Permissions Required:**
```yaml
permission:
  model:
    enabled: true  # Uses model for content processing
```

**Use Cases:**
- Crawl documentation websites
- Extract blog content
- Monitor web changes
- Build knowledge bases from websites

#### Jina Reader (`datasources/jina_datasource`)
**Features:**
- URL content extraction
- Automatic content cleaning
- Markdown output
- Multi-language support

**Provider Type:** `website_crawl`

**API Configuration:**
```yaml
credentials_schema:
  - name: api_key
    type: secret-input
    required: true
    label:
      en_US: Jina API Key
```

**Key Features:**
- Fast content extraction
- Clean markdown output
- No browser automation needed
- Cost-effective for simple scraping

---

## Agent Strategies

| Name | Directory | Description |
|------|-----------|-------------|
| cot_agent | `agent-strategies/cot_agent` | Chain-of-Thought reasoning strategy |

---

## Plugin Structure

### Standard Plugin Structure
```
plugin-name/
├── manifest.yaml          # Plugin metadata (name, version, description)
├── main.py               # Entry point
├── pyproject.toml        # uv dependency management
├── uv.lock               # Lock file (auto-generated)
├── requirements.txt      # Python dependencies (legacy)
├── provider/             # Provider configuration
│   ├── provider.py
│   └── provider.yaml
├── models/               # Model definitions (Models plugins)
├── tools/                # Tool definitions (Tools plugins)
├── datasources/          # Datasource definitions (Datasource plugins)
│   ├── datasource.py
│   └── datasource.yaml
└── _assets/              # Icons and assets
    └── icon.svg
```

### Datasource Plugin Structure
```
datasource-plugin/
├── manifest.yaml          # Plugin metadata
├── main.py               # Entry point: plugin = Plugin(DifyPluginEnv())
├── pyproject.toml        # uv dependencies
├── provider/
│   ├── provider.yaml     # Provider config with credentials_schema
│   └── provider.py       # Provider class with _validate_credentials()
├── datasources/
│   ├── datasource.yaml   # Datasource identity and parameters
│   └── datasource.py     # Datasource class implementing fetch logic
└── _assets/
    └── icon.svg
```

### Key Datasource Base Classes

**OnlineDocumentDatasource** - For document-based sources (GitHub, Notion, Confluence)
```python
from dify_plugin.interfaces.datasource.online_document import OnlineDocumentDatasource

class MyDataSource(OnlineDocumentDatasource):
    def validate_credentials(self) -> None:
        # Validate authentication
        pass
    
    def get_pages(self) -> DatasourceGetPagesResponse:
        # List available documents/pages
        pass
    
    def get_page_content(self, page_id: str) -> str:
        # Fetch specific document content
        pass
```

**OnlineDriveDatasource** - For file storage sources (S3, Google Drive, Dropbox)
```python
from dify_plugin.interfaces.datasource.online_drive import OnlineDriveDatasource

class MyDriveDataSource(OnlineDriveDatasource):
    def validate_credentials(self) -> None:
        # Validate storage access
        pass
    
    def get_files(self) -> List[FileInfo]:
        # List files and folders
        pass
    
    def download_file(self, file_id: str) -> bytes:
        # Download file content
        pass
```

When developing new plugins, refer to existing implementations of the same type.
