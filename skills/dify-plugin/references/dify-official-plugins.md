# Dify Official Plugins

This reference contains official plugin examples to study real implementations.

You can clone it from GitHub: [dify-official-plugins](https://github.com/langgenius/dify-official-plugins).

## Repo Overview

### All Plugin Types

| Type             | Directory Prefix    | Purpose                                   |
|------------------|---------------------|-------------------------------------------|
| Models           | `models/`           | LLM, Embedding, TTS provider integrations |
| Tools            | `tools/`            | External API and service integrations     |
| Extensions       | `extensions/`       | Platform feature extensions               |
| Triggers         | `triggers/`         | External event workflow triggers          |
| Datasources      | `datasources/`      | External data source integrations         |
| Agent Strategies | `agent-strategies/` | Agent reasoning strategies                |


#### Some of Model Plugins

| Name            | Directory                | Description              |
|-----------------|--------------------------|--------------------------|
| openai          | `models/openai`          | OpenAI GPT series        |
| anthropic       | `models/anthropic`       | Claude series            |
| azure_openai    | `models/azure_openai`    | Azure OpenAI Service     |
| deepseek        | `models/deepseek`        | DeepSeek models          |
| zhipuai         | `models/zhipuai`         | Zhipu AI                 |
| tongyi          | `models/tongyi`          | Alibaba Tongyi Qianwen   |
| siliconflow     | `models/siliconflow`     | SiliconFlow              |
| vertex_ai       | `models/vertex_ai`       | Google Vertex AI         |
| volcengine_maas | `models/volcengine_maas` | ByteDance Volcano Engine |
| cohere          | `models/cohere`          | Cohere models            |

---

## Some of Tool Plugins

| Name                   | Directory                      | Description             |
|------------------------|--------------------------------|-------------------------|
| feishu_base            | `tools/feishu_base`            | Feishu Bitable          |
| feishu_calendar        | `tools/feishu_calendar`        | Feishu Calendar         |
| feishu_message         | `tools/feishu_message`         | Feishu Messaging        |
| feishu_document        | `tools/feishu_document`        | Feishu Docs             |
| e2b                    | `tools/e2b`                    | Code sandbox execution  |
| lark_spreadsheet       | `tools/lark_spreadsheet`       | Lark Spreadsheet        |
| lark_task              | `tools/lark_task`              | Lark Tasks              |
| lark_message_and_group | `tools/lark_message_and_group` | Lark Messaging & Groups |
| lark_document          | `tools/lark_document`          | Lark Docs               |
| wikipedia              | `tools/wikipedia`              | Wikipedia search        |

---

## Some of Extension Plugins

| Name                       | Directory                               | Description                           |
|----------------------------|-----------------------------------------|---------------------------------------|
| slack_bot                  | `extensions/slack_bot`                  | Slack Bot integration                 |
| openai_compatible          | `extensions/openai_compatible`          | OpenAI-compatible API endpoint        |
| oaicompat_dify_model       | `extensions/oaicompat_dify_model`       | Dify model OpenAI compatibility layer |
| mcp_server                 | `extensions/mcp_server`                 | MCP server integration                |
| wecom_bot                  | `extensions/wecom_bot`                  | WeCom Bot                             |
| llamacloud                 | `extensions/llamacloud`                 | LlamaCloud integration                |
| badapple                   | `extensions/badapple`                   | Bad Apple demo                        |
| aws_bedrock_knowledge_base | `extensions/aws_bedrock_knowledge_base` | AWS Bedrock Knowledge Base            |

---

## Some of Trigger Plugins

| Name                | Directory                      | Description              |
|---------------------|--------------------------------|--------------------------|
| github_trigger      | `triggers/github_trigger`      | GitHub Webhook events    |
| slack_trigger       | `triggers/slack_trigger`       | Slack events             |
| lark_trigger        | `triggers/lark_trigger`        | Feishu/Lark events       |
| linear_trigger      | `triggers/linear_trigger`      | Linear events            |
| telegram_trigger    | `triggers/telegram_trigger`    | Telegram Bot messages    |
| notion_trigger      | `triggers/notion_trigger`      | Notion change events     |
| woocommerce_trigger | `triggers/woocommerce_trigger` | WooCommerce order events |
| zendesk_trigger     | `triggers/zendesk_trigger`     | Zendesk ticket events    |
| gmail_trigger       | `triggers/gmail_trigger`       | Gmail events             |
| outlook_trigger     | `triggers/outlook_trigger`     | Outlook email events     |

---

## Some of Datasource Plugins

| Name                  | Directory                           | Description                                                                 | Provider Type     | Auth Method                                |
|-----------------------|-------------------------------------|-----------------------------------------------------------------------------|-------------------|--------------------------------------------|
| aws_s3_storage        | `datasources/aws_s3_storage`        | AWS S3 Storage - Access buckets and objects                                 | `online_drive`    | Access Key + Secret                        |
| azure_blob            | `datasources/azure_blob`            | Azure Blob Storage - Access containers and blobs with multiple auth methods | `online_drive`    | Access Key / SAS Token / Connection String |
| github                | `datasources/github`                | GitHub Repository - Access repos, issues, PRs, and wiki pages               | `online_document` | Personal Access Token / OAuth              |
| google_drive          | `datasources/google_drive`          | Google Drive - Access files and folders                                     | `online_drive`    | OAuth                                      |
| notion_datasource     | `datasources/notion_datasource`     | Notion - Access pages and databases                                         | `online_document` | OAuth / Internal Integration Token         |
| confluence_datasource | `datasources/confluence_datasource` | Confluence - Access spaces and pages                                        | `online_document` | API Token / OAuth                          |
| dropbox_datasource    | `datasources/dropbox_datasource`    | Dropbox - Access files and folders                                          | `online_drive`    | OAuth / Access Token                       |
| firecrawl_datasource  | `datasources/firecrawl_datasource`  | Firecrawl - Web crawling and content extraction                             | `website_crawl`   | API Key                                    |
| jina_datasource       | `datasources/jina_datasource`       | Jina Reader - Web content extraction and parsing                            | `website_crawl`   | API Key                                    |
| onedrive              | `datasources/onedrive`              | OneDrive - Access files and folders                                         | `online_drive`    | OAuth                                      |

## Some of Agent Strategy Plugins

| Name      | Directory                    | Description                         |
|-----------|------------------------------|-------------------------------------|
| cot_agent | `agent-strategies/cot_agent` | Chain-of-Thought reasoning strategy |
