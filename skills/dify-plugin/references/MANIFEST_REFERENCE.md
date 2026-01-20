# Dify Plugin Manifest.yaml 完整参考指南

本文档提供 manifest.yaml 的完整字段规则、验证约束和示例，帮助开发者正确编写插件清单文件。

## 目录

1. [基础结构](#1-基础结构)
2. [字段验证规则详解](#2-字段验证规则详解)
3. [各插件类型声明](#3-各插件类型声明)
4. [完整示例](#4-完整示例)
5. [常见错误与解决方案](#5-常见错误与解决方案)

---

## 1. 基础结构

### 1.1 manifest.yaml 顶层结构

```yaml
# 基础信息 (必需)
version: "0.0.1"              # 语义化版本
type: plugin                   # 固定值
author: your-name              # 作者名
name: plugin-name              # 插件名
label:                         # 多语言标签
  en_US: "Plugin Name"
  zh_Hans: "插件名称"
description:                   # 多语言描述
  en_US: "Plugin description"
  zh_Hans: "插件描述"
icon: icon.svg                 # 图标路径
created_at: 2024-01-01T00:00:00Z  # 创建时间

# 运行时元信息 (必需)
meta:
  version: "0.0.1"
  arch:
    - amd64
    - arm64
  runner:
    language: python
    version: "3.12"
    entrypoint: main

# 资源要求 (必需)
resource:
  memory: 268435456            # 内存限制 (字节)
  permission:                  # 权限配置 (可选)
    tool:
      enabled: true
    model:
      enabled: true
    storage:
      enabled: true
      size: 1048576            # 1MB

# 插件组件声明 (必需，至少一个)
plugins:
  tools:
    - provider/tools/my_tool.yaml
  models: []
  endpoints: []
  agent_strategies: []
  datasources: []
  triggers: []

# 可选字段
icon_dark: icon_dark.svg       # 深色主题图标
tags:                          # 分类标签
  - productivity
  - utilities
privacy: "https://example.com/privacy"   # 隐私政策 URL
repo: "https://github.com/user/repo"     # 代码仓库 URL

# 提供者声明 (根据插件类型选择)
tool: ...                      # Tool 插件声明
model: ...                     # Model 插件声明
agent_strategy: ...            # Agent Strategy 插件声明
datasource: ...                # Datasource 插件声明
trigger: ...                   # Trigger 插件声明
endpoint: ...                  # Endpoint 插件声明
```

---

## 2. 字段验证规则详解

### 2.1 版本号 (version)

**规则**: `^\d{1,4}(\.\d{1,4}){2}(-\w{1,16})?$`

| 示例 | 有效性 | 说明 |
|------|--------|------|
| `0.0.1` | ✅ | 标准语义化版本 |
| `1.2.3` | ✅ | 标准语义化版本 |
| `1.0.0-beta` | ✅ | 带预发布标识 |
| `1.0.0-alpha1` | ✅ | 带预发布标识 |
| `1` | ❌ | 缺少次版本号和补丁号 |
| `1.0` | ❌ | 缺少补丁号 |
| `1.0.0.0.0` | ❌ | 版本段过多 |
| `v1.0.0` | ❌ | 不能有 "v" 前缀 |

### 2.2 类型 (type)

**规则**: 必须等于 `plugin`

```yaml
type: plugin  # 唯一有效值
```

### 2.3 作者名 (author)

**规则**: `^[a-z0-9_-]{1,64}$`

| 示例 | 有效性 | 说明 |
|------|--------|------|
| `langgenius` | ✅ | 小写字母 |
| `my-company` | ✅ | 带连字符 |
| `user_123` | ✅ | 带下划线和数字 |
| `MyCompany` | ❌ | 不能有大写字母 |
| `my company` | ❌ | 不能有空格 |
| `a` | ✅ | 最短 1 字符 |
| `a...64chars...` | ✅ | 最长 64 字符 |

### 2.4 插件名 (name)

**规则**: `^[a-z0-9_-]{1,128}$`

| 示例 | 有效性 | 说明 |
|------|--------|------|
| `my-plugin` | ✅ | 带连字符 |
| `my_tool_v2` | ✅ | 带下划线和数字 |
| `MyPlugin` | ❌ | 不能有大写字母 |
| `my plugin` | ❌ | 不能有空格 |

### 2.5 多语言对象 (I18nObject)

```yaml
label:
  en_US: "English Label"      # 必需，1-1023 字符
  zh_Hans: "中文标签"          # 可选，最长 1023 字符
  ja_JP: "日本語ラベル"        # 可选，最长 1023 字符
  pt_BR: "Rótulo em Português" # 可选，最长 1023 字符
```

**规则**:
- `en_US`: **必需**，长度 1-1023 字符
- `zh_Hans`, `ja_JP`, `pt_BR`: 可选，最长 1023 字符

### 2.6 图标 (icon)

**规则**: 必需，最长 128 字符

```yaml
icon: icon.svg                 # 相对于插件根目录的路径
icon_dark: icon_dark.svg       # 可选，深色主题图标
```

### 2.7 运行时元信息 (meta)

```yaml
meta:
  version: "0.0.1"             # 必需，语义化版本
  arch:                        # 必需，支持的架构
    - amd64                    # x86_64 架构
    - arm64                    # ARM64 架构
  runner:                      # 必需，运行时配置
    language: python           # 必需，目前仅支持 "python"
    version: "3.12"            # 必需，Python 版本，最长 128 字符
    entrypoint: main           # 必需，入口模块，最长 256 字符
  minimum_dify_version: "0.8.0" # 可选，最低 Dify 版本
```

**支持的架构**:
- `amd64` - x86_64 架构
- `arm64` - ARM64 架构

**支持的语言**:
- `python` - 目前唯一支持的语言

### 2.8 资源要求 (resource)

```yaml
resource:
  memory: 268435456            # 必需，内存限制 (字节)
  permission:                  # 可选，权限配置
    tool:
      enabled: true            # 启用工具调用权限
    model:
      enabled: true            # 启用模型调用权限
      llm: true                # LLM 调用
      text_embedding: true     # 文本向量化
      rerank: true             # 重排序
      tts: true                # 文本转语音
      speech2text: true        # 语音转文本
      moderation: true         # 内容审核
    node:
      enabled: true            # 启用节点调用权限
    endpoint:
      enabled: true            # 启用端点注册权限
    app:
      enabled: true            # 启用应用调用权限
    storage:
      enabled: true            # 启用存储权限
      size: 1048576            # 存储大小限制 (字节)
```

**存储大小限制**:
- 最小: 1024 字节 (1 KB)
- 最大: 1073741824 字节 (1 GB)

### 2.9 插件组件声明 (plugins)

```yaml
plugins:
  tools:                       # 工具定义文件列表
    - provider/tools/tool1.yaml
    - provider/tools/tool2.yaml
  models:                      # 模型定义文件列表
    - provider/models/model1.yaml
  endpoints:                   # 端点定义文件列表
    - provider/endpoints/endpoint1.yaml
  agent_strategies:            # Agent 策略定义文件列表
    - provider/agent_strategies/strategy1.yaml
  datasources:                 # 数据源定义文件列表
    - provider/datasources/ds1.yaml
  triggers:                    # 触发器定义文件列表
    - provider/triggers/trigger1.yaml
```

**规则**: 每个路径最长 128 字符

### 2.10 标签 (tags)

**有效标签值**:
```yaml
tags:
  - search           # 搜索
  - image            # 图像
  - videos           # 视频
  - weather          # 天气
  - finance          # 金融
  - design           # 设计
  - travel           # 旅行
  - social           # 社交
  - news             # 新闻
  - medical          # 医疗
  - productivity     # 生产力
  - education        # 教育
  - business         # 商业
  - entertainment    # 娱乐
  - utilities        # 工具
  - agent            # Agent
  - rag              # RAG
  - other            # 其他
  - trigger          # 触发器
```

### 2.11 插件类型互斥规则

| 声明的类型 | 可组合 | 不可组合 |
|-----------|--------|---------|
| `tool` | `endpoint` | `model`, `agent_strategy`, `datasource`, `trigger` |
| `model` | 无 | 所有其他类型 |
| `agent_strategy` | 无 | 所有其他类型 |
| `datasource` | 无 | 所有其他类型 |
| `trigger` | 无 | 所有其他类型 |
| `endpoint` | `tool` | `model`, `agent_strategy`, `datasource`, `trigger` |

---

## 3. 各插件类型声明

### 3.1 Tool 插件声明

```yaml
tool:
  identity:
    author: your-name            # 必需
    name: tool-provider-name     # 必需，正则: ^[a-zA-Z0-9_-]+$
    description:                 # 可选
      en_US: "Provider description"
      zh_Hans: "提供者描述"
    icon: icon.svg               # 必需
    icon_dark: icon_dark.svg     # 可选
    label:                       # 必需
      en_US: "Provider Label"
      zh_Hans: "提供者标签"
    tags:                        # 可选
      - productivity

  credentials_schema:            # 可选，凭证配置
    - name: api_key              # 字段名，1-1023 字符
      type: secret-input         # 类型 (见下方)
      required: true             # 是否必需
      default: ""                # 默认值
      label:
        en_US: "API Key"
        zh_Hans: "API 密钥"
      help:                      # 帮助文本
        en_US: "Enter your API key"
      placeholder:               # 占位符
        en_US: "sk-..."
      url: "https://example.com/api-keys"  # 帮助链接

  oauth_schema:                  # 可选，OAuth 配置
    client_schema:
      - name: client_id
        type: text-input
        required: true
        label:
          en_US: "Client ID"
    credentials_schema:
      - name: access_token
        type: secret-input
        required: true
        label:
          en_US: "Access Token"

  tools:                         # 必需，工具列表
    - identity:
        author: your-name        # 必需
        name: tool-name          # 必需，正则: ^[a-zA-Z0-9_-]+$
        label:
          en_US: "Tool Label"
          zh_Hans: "工具标签"
      description:               # 必需
        human:
          en_US: "Human-readable description"
          zh_Hans: "人类可读描述"
        llm: "LLM-readable description for tool selection"
      parameters:                # 工具参数
        - name: query            # 参数名，1-1023 字符
          type: string           # 参数类型 (见下方)
          label:
            en_US: "Query"
            zh_Hans: "查询"
          human_description:     # 必需
            en_US: "Search query"
            zh_Hans: "搜索查询"
          llm_description: "The search query string"  # LLM 描述
          form: llm              # 表单类型: schema | form | llm
          required: true         # 是否必需
          default: ""            # 默认值
          min: 0                 # 最小值 (数字类型)
          max: 100               # 最大值 (数字类型)
          precision: 2           # 精度 (数字类型)
          options:               # 选项 (select 类型)
            - value: option1
              label:
                en_US: "Option 1"
          scope: "all"           # 作用域 (特定类型)
      output_schema:             # 可选，输出 JSON Schema
        type: object
        properties:
          result:
            type: string
      has_runtime_parameters: false  # 是否有运行时参数
```

#### 凭证/配置类型 (credentials_schema.type)

| 类型 | 说明 |
|------|------|
| `secret-input` | 敏感输入 (如 API 密钥) |
| `text-input` | 普通文本输入 |
| `select` | 下拉选择 |
| `boolean` | 布尔开关 |
| `model-selector` | 模型选择器 |
| `app-selector` | 应用选择器 |
| `array[tools]` | 工具数组选择器 |
| `any` | 任意类型 |

#### 工具参数类型 (parameters.type)

| 类型 | 说明 |
|------|------|
| `string` | 字符串 |
| `number` | 数字 |
| `boolean` | 布尔值 |
| `select` | 下拉选择 |
| `secret-input` | 敏感输入 |
| `file` | 单个文件 |
| `files` | 多个文件 |
| `app-selector` | 应用选择器 |
| `model-selector` | 模型选择器 |
| `any` | 任意类型 |
| `dynamic-select` | 动态下拉选择 |
| `array` | 数组 |
| `object` | 对象 |
| `checkbox` | 复选框 |

#### 参数表单类型 (parameters.form)

| 类型 | 说明 |
|------|------|
| `schema` | 在 Schema 中定义 |
| `form` | 用户表单输入 |
| `llm` | LLM 自动填充 |

#### 作用域 (scope) 配置

**model-selector 作用域**:
```yaml
scope: "llm"                    # 单个
scope: "llm&text-embedding"     # 组合使用 & 分隔
```
有效值: `all`, `llm`, `text-embedding`, `rerank`, `tts`, `speech2text`, `moderation`, `vision`, `document`, `tool-call`

**app-selector 作用域**:
```yaml
scope: "all"                    # 所有应用
scope: "chat&workflow"          # 组合
```
有效值: `all`, `chat`, `workflow`, `completion`

**any 作用域**:
```yaml
scope: "string"                 # 字符串
scope: "string&number&object"   # 组合
```
有效值: `string`, `number`, `object`, `array[number]`, `array[string]`, `array[object]`, `array[file]`

---

### 3.2 Model 插件声明

```yaml
model:
  provider: provider-name        # 必需，最长 255 字符
  label:                         # 必需
    en_US: "Provider Name"
    zh_Hans: "提供者名称"
  description:                   # 可选
    en_US: "Provider description"
  icon_small:                    # 可选，小图标
    en_US: icon_small.svg
  icon_large:                    # 可选，大图标
    en_US: icon_large.svg
  background: "#FFFFFF"          # 可选，背景色
  help:                          # 可选，帮助信息
    title:
      en_US: "Help Title"
    url:
      en_US: "https://help.example.com"

  supported_model_types:         # 必需，支持的模型类型
    - llm
    - text-embedding
    - rerank
    - speech2text
    - moderation
    - tts
    - text2img
    - multimodal-embedding
    - multimodal-rerank

  configurate_methods:           # 必需，配置方法
    - predefined-model           # 预定义模型
    - customizable-model         # 可自定义模型

  provider_credential_schema:    # 可选，提供者凭证
    credential_form_schemas:
      - variable: api_key        # 变量名，最长 255 字符
        label:
          en_US: "API Key"
        type: secret-input       # text-input | secret-input | select | radio | switch
        required: true
        default: ""              # 最长 255 字符
        placeholder:
          en_US: "Enter API key"
        max_length: 256
        options:                 # select/radio 类型
          - label:
              en_US: "Option 1"
            value: option1       # 最长 255 字符
            show_on:             # 条件显示
              - variable: other_field
                value: some_value
        show_on:                 # 条件显示
          - variable: provider_type
            value: custom

  model_credential_schema:       # 可选，模型凭证
    model:
      label:
        en_US: "Model Name"
      placeholder:
        en_US: "Enter model name"
    credential_form_schemas:
      - variable: model_id
        label:
          en_US: "Model ID"
        type: text-input
        required: true

  models:                        # 可选，预定义模型列表
    - model: gpt-4               # 必需，模型标识，最长 255 字符
      label:
        en_US: "GPT-4"
      model_type: llm            # 必需
      features:                  # 可选，特性列表
        - vision
        - tool-use
      fetch_from: predefined-model  # predefined-model | customizable-model
      model_properties:          # 可选，模型属性
        context_size: 128000
        max_tokens: 4096
      deprecated: false          # 是否废弃
      parameter_rules:           # 参数规则，最多 128 个
        - name: temperature      # 必需，最长 255 字符
          use_template: temperature  # 使用预定义模板
        - name: max_tokens
          label:
            en_US: "Max Tokens"
          type: int              # float | int | string | boolean | text
          required: false
          default: 4096
          min: 1
          max: 128000
          help:
            en_US: "Maximum output tokens"
      pricing:                   # 可选，定价信息
        input: 0.00003
        output: 0.00006
        unit: 0.001
        currency: USD
```

#### 模型类型 (model_type)

| 类型 | 说明 |
|------|------|
| `llm` | 语言模型 |
| `text-embedding` | 文本向量化 |
| `rerank` | 重排序 |
| `speech2text` | 语音转文本 |
| `moderation` | 内容审核 |
| `tts` | 文本转语音 |
| `text2img` | 文本生成图片 |
| `multimodal-embedding` | 多模态向量化 |
| `multimodal-rerank` | 多模态重排序 |

#### 参数模板 (use_template)

预定义的参数模板，可直接引用:
- `temperature` - 温度参数
- `top_p` - Top-P 采样
- `top_k` - Top-K 采样
- `presence_penalty` - 存在惩罚
- `frequency_penalty` - 频率惩罚
- `max_tokens` - 最大 Token 数
- `response_format` - 响应格式
- `json_schema` - JSON Schema

---

### 3.3 Agent Strategy 插件声明

```yaml
agent_strategy:
  identity:
    author: your-name           # 必需
    name: strategy-provider     # 必需，正则: ^[a-zA-Z0-9_-]+$
    description:
      en_US: "Strategy provider description"
    icon: icon.svg              # 必需
    label:
      en_US: "Strategy Provider"
    tags:
      - agent

  strategies:                   # 必需
    - identity:
        author: your-name       # 必需
        name: my-strategy       # 必需，正则: ^[a-zA-Z0-9_-]+$
        label:
          en_US: "My Strategy"
      description:              # 必需
        en_US: "Strategy description"
      parameters:
        - name: model
          type: model-selector  # 特有: array[tools] (工具选择器)
          scope: "llm"
          required: true
          label:
            en_US: "Model"
          human_description:
            en_US: "Select a model"
          form: form
        - name: tools
          type: array[tools]    # Agent 特有类型
          required: true
          label:
            en_US: "Tools"
          human_description:
            en_US: "Select tools"
          form: form
      output_schema:            # 可选
        type: object
        properties:
          result:
            type: string
      features:                 # 可选，特性列表
        - streaming
```

#### Agent 参数类型

除了通用类型外，Agent Strategy 特有:
- `array[tools]` - 工具选择器，允许选择可用工具

---

### 3.4 Datasource 插件声明

```yaml
datasource:
  identity:
    author: your-name           # 必需
    name: datasource-provider   # 必需
    description:                # 必需
      en_US: "Datasource provider"
    icon: icon.svg              # 必需
    label:                      # 必需
      en_US: "Datasource Provider"
    tags:
      - productivity

  credentials_schema:           # 可选
    - name: api_key
      type: secret-input
      required: true
      label:
        en_US: "API Key"

  oauth_schema:                 # 可选
    client_schema: []
    credentials_schema: []

  provider_type: website_crawl  # 必需，数据源类型
  # 有效值: website_crawl | online_document | online_drive

  datasources:                  # 必需
    - identity:
        author: your-name       # 必需
        name: crawler           # 必需
        label:
          en_US: "Web Crawler"
      parameters:               # 必需，至少一个
        - name: url
          type: string          # string | number | boolean | select | secret-input
          required: true
          label:
            en_US: "URL"
          description:
            en_US: "URL to crawl"
      description:              # 必需
        en_US: "Crawl a website"
      output_schema:            # 可选
        type: object
        properties:
          content:
            type: string
```

#### 数据源类型 (provider_type)

| 类型 | 说明 |
|------|------|
| `website_crawl` | 网站爬取 |
| `online_document` | 在线文档 |
| `online_drive` | 云盘存储 |

---

### 3.5 Trigger 插件声明

```yaml
trigger:
  identity:
    author: your-name           # 必需
    name: trigger-provider      # 必需，正则: ^[a-zA-Z0-9_-]+$
    description:
      en_US: "Trigger provider"
    icon: icon.svg              # 必需
    icon_dark: icon_dark.svg    # 可选
    label:                      # 必需
      en_US: "Trigger Provider"
    tags:
      - trigger

  subscription_schema:          # 必需，订阅参数
    - name: webhook_url
      type: text-input
      required: true
      label:
        en_US: "Webhook URL"

  subscription_constructor:     # 可选，订阅构造器
    parameters:
      - name: event_type
        type: select
        required: true
        label:
          en_US: "Event Type"
        options:
          - value: push
            label:
              en_US: "Push"
    credentials_schema:
      - name: secret
        type: secret-input
        required: true
        label:
          en_US: "Secret"
    oauth_schema:               # 可选
      client_schema: []
      credentials_schema: []

  events:                       # 可选，事件列表
    - identity:
        author: your-name       # 必需
        name: on-push           # 必需，正则: ^[a-zA-Z0-9_-]+$
        label:
          en_US: "On Push"
      parameters:
        - name: branch
          type: string          # string | number | boolean | select | file | files | model-selector | app-selector | object | array | dynamic-select | checkbox
          required: false
          label:
            en_US: "Branch"
      description:              # 必需
        en_US: "Triggered on push event"
      output_schema:            # 可选
        type: object
        properties:
          commit_id:
            type: string
```

---

### 3.6 Endpoint 插件声明

```yaml
endpoint:
  settings:                     # 可选，端点配置
    - name: base_path
      type: text-input
      required: false
      label:
        en_US: "Base Path"

  endpoints:                    # 端点列表
    - path: /api/webhook        # 必需
      method: POST              # 必需: HEAD | GET | POST | PUT | DELETE | OPTIONS
      hidden: false             # 可选，是否隐藏
    - path: /api/status
      method: GET

  endpoint_files:               # 可选，端点定义文件
    - endpoints/webhook.yaml
```

---

## 4. 完整示例

### 4.1 Tool 插件完整示例

```yaml
version: "1.0.0"
type: plugin
author: langgenius
name: web-search
label:
  en_US: "Web Search"
  zh_Hans: "网页搜索"
description:
  en_US: "Search the web using various search engines"
  zh_Hans: "使用多种搜索引擎搜索网页"
icon: icon.svg
icon_dark: icon_dark.svg
created_at: 2024-01-01T00:00:00Z

meta:
  version: "1.0.0"
  arch:
    - amd64
    - arm64
  runner:
    language: python
    version: "3.12"
    entrypoint: main
  minimum_dify_version: "0.8.0"

resource:
  memory: 268435456
  permission:
    tool:
      enabled: true
    storage:
      enabled: true
      size: 10485760

plugins:
  tools:
    - provider/tools/search.yaml

tags:
  - search
  - productivity

tool:
  identity:
    author: langgenius
    name: web-search
    description:
      en_US: "Web search provider"
      zh_Hans: "网页搜索提供者"
    icon: icon.svg
    label:
      en_US: "Web Search"
      zh_Hans: "网页搜索"
    tags:
      - search

  credentials_schema:
    - name: api_key
      type: secret-input
      required: true
      label:
        en_US: "API Key"
        zh_Hans: "API 密钥"
      help:
        en_US: "Get your API key from the dashboard"
        zh_Hans: "从控制台获取 API 密钥"
      placeholder:
        en_US: "Enter your API key"
        zh_Hans: "输入您的 API 密钥"
    - name: search_engine
      type: select
      required: true
      default: google
      label:
        en_US: "Search Engine"
        zh_Hans: "搜索引擎"
      options:
        - value: google
          label:
            en_US: "Google"
        - value: bing
          label:
            en_US: "Bing"

  tools:
    - identity:
        author: langgenius
        name: search
        label:
          en_US: "Search"
          zh_Hans: "搜索"
      description:
        human:
          en_US: "Search the web for information"
          zh_Hans: "搜索网页获取信息"
        llm: "Search the web using the specified query and return relevant results"
      parameters:
        - name: query
          type: string
          label:
            en_US: "Query"
            zh_Hans: "查询"
          human_description:
            en_US: "The search query"
            zh_Hans: "搜索查询"
          llm_description: "The search query string"
          form: llm
          required: true
        - name: max_results
          type: number
          label:
            en_US: "Max Results"
            zh_Hans: "最大结果数"
          human_description:
            en_US: "Maximum number of results to return"
            zh_Hans: "返回的最大结果数"
          form: form
          required: false
          default: 10
          min: 1
          max: 100
      output_schema:
        type: object
        properties:
          results:
            type: array
            items:
              type: object
              properties:
                title:
                  type: string
                url:
                  type: string
                snippet:
                  type: string
```

### 4.2 Model 插件完整示例

```yaml
version: "1.0.0"
type: plugin
author: langgenius
name: openai-compatible
label:
  en_US: "OpenAI Compatible"
  zh_Hans: "OpenAI 兼容"
description:
  en_US: "OpenAI API compatible model provider"
  zh_Hans: "OpenAI API 兼容模型提供者"
icon: icon.svg
created_at: 2024-01-01T00:00:00Z

meta:
  version: "1.0.0"
  arch:
    - amd64
    - arm64
  runner:
    language: python
    version: "3.12"
    entrypoint: main

resource:
  memory: 536870912
  permission:
    model:
      enabled: true
      llm: true
      text_embedding: true

plugins:
  models:
    - provider/models/llm.yaml
    - provider/models/embedding.yaml

tags:
  - utilities

model:
  provider: openai-compatible
  label:
    en_US: "OpenAI Compatible"
    zh_Hans: "OpenAI 兼容"
  description:
    en_US: "Connect to any OpenAI API compatible endpoint"
    zh_Hans: "连接任何 OpenAI API 兼容端点"
  icon_small:
    en_US: icon_small.svg
  icon_large:
    en_US: icon_large.svg

  supported_model_types:
    - llm
    - text-embedding

  configurate_methods:
    - customizable-model

  provider_credential_schema:
    credential_form_schemas:
      - variable: api_key
        label:
          en_US: "API Key"
          zh_Hans: "API 密钥"
        type: secret-input
        required: true
        placeholder:
          en_US: "Enter your API key"
      - variable: api_base
        label:
          en_US: "API Base URL"
          zh_Hans: "API 基础 URL"
        type: text-input
        required: true
        default: "https://api.openai.com/v1"
        placeholder:
          en_US: "https://api.openai.com/v1"

  model_credential_schema:
    model:
      label:
        en_US: "Model Name"
        zh_Hans: "模型名称"
      placeholder:
        en_US: "e.g., gpt-4"
    credential_form_schemas:
      - variable: context_size
        label:
          en_US: "Context Size"
          zh_Hans: "上下文大小"
        type: text-input
        required: false
        default: "4096"
```

---

## 5. 常见错误与解决方案

### 5.1 版本号错误

```
❌ 错误: version: "1"
   信息: Field validation for 'Version' failed on the 'version' tag

✅ 正确: version: "1.0.0"
```

### 5.2 名称格式错误

```
❌ 错误: name: "My Plugin"
   信息: plugin name not match regex pattern

✅ 正确: name: "my-plugin"
```

### 5.3 缺少必需字段

```
❌ 错误: label: {}
   信息: Field validation for 'EnUS' failed on the 'required' tag

✅ 正确:
   label:
     en_US: "Label"
```

### 5.4 存储大小超限

```
❌ 错误: size: 500  # 小于 1024
   信息: Field validation for 'Size' failed on the 'min' tag

❌ 错误: size: 2147483648  # 大于 1GB
   信息: Field validation for 'Size' failed on the 'max' tag

✅ 正确: size: 1048576  # 1MB
```

### 5.5 类型互斥错误

```
❌ 错误: 同时声明 model 和 tool
   信息: model and tool cannot be provided at the same time

✅ 正确: 只声明一种独占类型，或使用允许的组合 (tool + endpoint)
```

### 5.6 无效的参数类型

```
❌ 错误: type: "invalid-type"
   信息: Field validation for 'Type' failed on the 'tool_parameter_type' tag

✅ 正确: type: "string"
```

### 5.7 无效的标签

```
❌ 错误: tags: ["invalid-tag"]
   信息: Field validation for 'Tags[0]' failed on the 'plugin_tag' tag

✅ 正确: tags: ["productivity", "utilities"]
```

### 5.8 scope 配置错误

```
❌ 错误:
   type: app-selector
   scope: "invalid"
   信息: Field validation for 'Scope' failed on the 'is_scope' tag

✅ 正确:
   type: app-selector
   scope: "all"  # 或 "chat", "workflow", "completion"
```

---

## 附录: 验证器注册表

所有自定义验证器列表 (定义于 `pkg/validators/`):

| 验证器名 | 用途 |
|---------|------|
| `version` | 语义化版本验证 |
| `plugin_tag` | 插件标签验证 |
| `is_available_language` | 编程语言验证 |
| `is_available_arch` | CPU 架构验证 |
| `tool_identity_name` | 工具名称验证 |
| `tool_parameter_type` | 工具参数类型验证 |
| `tool_parameter_form` | 参数表单类型验证 |
| `tool_provider_identity_name` | 工具提供者名称验证 |
| `parameter_auto_generate_type` | 参数自动生成类型验证 |
| `is_basic_type` | 基础类型验证 |
| `model_type` | 模型类型验证 |
| `model_provider_configurate_method` | 模型配置方法验证 |
| `model_provider_form_type` | 模型表单类型验证 |
| `model_parameter_type` | 模型参数类型验证 |
| `parameter_rule` | 参数规则验证 |
| `is_available_endpoint_method` | HTTP 方法验证 |
| `event_parameter_type` | 事件参数类型验证 |
| `event_identity_name` | 事件名称验证 |
| `trigger_provider_identity_name` | 触发器提供者名称验证 |
| `agent_strategy_parameter_type` | Agent 策略参数类型验证 |
| `datasource_provider_type` | 数据源类型验证 |
| `datasource_parameter_type` | 数据源参数类型验证 |
| `credential_type` | 凭证类型验证 |
| `is_scope` | 作用域验证 |
| `is_app_selector_scope` | 应用选择器作用域验证 |
| `is_model_config_scope` | 模型配置作用域验证 |
| `is_tool_selector_scope` | 工具选择器作用域验证 |
| `plugin_unique_identifier` | 插件唯一标识符验证 |
