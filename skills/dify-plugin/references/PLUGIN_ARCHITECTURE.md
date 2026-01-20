# Dify Plugin 工作原理详解

本文档详细介绍 Dify Plugin Daemon 的插件系统工作原理，包括生命周期、钩子函数和变量约定。

## 目录

1. [插件类型概述](#1-插件类型概述)
2. [运行时类型](#2-运行时类型)
3. [插件生命周期](#3-插件生命周期)
4. [钩子函数与回调机制](#4-钩子函数与回调机制)
5. [变量约定与配置](#5-变量约定与配置)
6. [各类型插件详解](#6-各类型插件详解)
7. [插件目录结构](#7-插件目录结构)

---

## 1. 插件类型概述

Dify 支持六种主要插件类型，定义于 `pkg/entities/plugin_entities/plugin_declaration.go`:

```go
type PluginCategory string

const (
    PLUGIN_CATEGORY_TOOL           PluginCategory = "tool"           // 工具插件
    PLUGIN_CATEGORY_MODEL          PluginCategory = "model"          // 模型插件
    PLUGIN_CATEGORY_EXTENSION      PluginCategory = "extension"      // 扩展插件
    PLUGIN_CATEGORY_AGENT_STRATEGY PluginCategory = "agent-strategy" // Agent策略插件
    PLUGIN_CATEGORY_DATASOURCE     PluginCategory = "datasource"     // 数据源插件
    PLUGIN_CATEGORY_TRIGGER        PluginCategory = "trigger"        // 触发器插件
)
```

### 1.1 插件类型互斥规则

| 插件类型 | 可与其他类型组合 | 说明 |
|---------|-----------------|------|
| Tool | 是 (可与 Endpoint 组合) | 可复用工具函数 |
| Model | 否 | 独占，提供 AI 模型能力 |
| Agent Strategy | 否 | 独占，提供 Agent 推理策略 |
| Datasource | 否 | 独占，提供数据源连接 |
| Trigger | 否 | 独占，提供事件触发能力 |
| Endpoint | 是 (可与 Tool 组合) | HTTP 端点扩展 |

---

## 2. 运行时类型

定义于 `pkg/entities/plugin_entities/runtime.go`:

```go
type PluginRuntimeType string

const (
    PLUGIN_RUNTIME_TYPE_LOCAL      PluginRuntimeType = "local"      // 本地进程
    PLUGIN_RUNTIME_TYPE_REMOTE     PluginRuntimeType = "remote"     // 远程调试
    PLUGIN_RUNTIME_TYPE_SERVERLESS PluginRuntimeType = "serverless" // 无服务器
)
```

### 2.1 运行时对比

| 特性 | Local | Remote/Debug | Serverless |
|-----|-------|--------------|------------|
| 进程模型 | 子进程 | TCP 连接 | HTTP 请求 |
| 通信协议 | STDIN/STDOUT (JSON) | TCP 二进制 + 换行符 | HTTP SSE |
| 并发模式 | 多实例 (副本) | 单连接 | 按请求 |
| 生命周期 | 长期进程 | 持久连接 | 无状态 |
| 心跳超时 | 120 秒 | 60 秒 | 按请求超时 |
| 负载均衡 | 轮询 | N/A | N/A |
| 适用场景 | 生产部署 | 开发调试 | 云端部署 |

### 2.2 运行时状态

```go
const (
    PLUGIN_RUNTIME_STATUS_ACTIVE     = "active"     // 运行中
    PLUGIN_RUNTIME_STATUS_LAUNCHING  = "launching"  // 启动中
    PLUGIN_RUNTIME_STATUS_STOPPED    = "stopped"    // 已停止
    PLUGIN_RUNTIME_STATUS_RESTARTING = "restarting" // 重启中
    PLUGIN_RUNTIME_STATUS_PENDING    = "pending"    // 等待中
)
```

---

## 3. 插件生命周期

### 3.1 完整生命周期流程

```
┌─────────────────────────────────────────────────────────────────┐
│                         安装阶段                                  │
├─────────────────────────────────────────────────────────────────┤
│  1. InstallMultiplePluginsToTenant()                            │
│     ↓                                                           │
│  2. DisableAutoLaunch() - 防止 WatchDog 提前启动                  │
│     ↓                                                           │
│  3. InstallToLocal() - 复制包到安装目录                           │
│     ↓                                                           │
│  4. LaunchLocalPlugin() - 启动运行时                             │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         初始化阶段                                │
├─────────────────────────────────────────────────────────────────┤
│  5. AcquireLock + Semaphore - 获取锁和信号量                      │
│     ↓                                                           │
│  6. BuildRuntime() - 构建运行时实例                               │
│     ↓                                                           │
│  7. AcquireDistributedLock (Redis) - 集群模式分布式锁             │
│     ↓                                                           │
│  8. InitEnvironment()                                           │
│     ├── ExtractPlugin - 解压插件                                 │
│     └── InitPythonEnv                                           │
│         ├── CreateVenv - 创建虚拟环境                            │
│         ├── InstallDeps (UV) - 安装依赖                          │
│         └── PreCompile - 预编译                                  │
│     ↓                                                           │
│  9. MountNotifiers() - 挂载生命周期通知器                         │
│     ↓                                                           │
│  10. Schedule() - 启动调度循环                                   │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         运行阶段                                  │
├─────────────────────────────────────────────────────────────────┤
│  11. startNewInstance() - 启动子进程                             │
│      ↓                                                          │
│  12. Wait for Heartbeat (最长 120 秒)                           │
│      ↓                                                          │
│  13. OnInstanceReady() - 实例就绪通知                            │
│      ↓                                                          │
│  14. 进入正常服务状态                                             │
│      ├── Listen() - 注册会话监听                                 │
│      ├── Write() - 发送请求到插件                                │
│      └── Heartbeat Monitor (每 30 秒)                           │
└─────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────┐
│                         关闭阶段                                  │
├─────────────────────────────────────────────────────────────────┤
│  15. GracefulStop() / Stop()                                    │
│      ↓                                                          │
│  16. Stop schedule loop                                         │
│      ↓                                                          │
│  17. For each instance:                                         │
│      ├── Wait for listeners (graceful)                          │
│      ├── Close stdin/stdout/stderr                              │
│      └── Kill subprocess + Reap                                 │
│      ↓                                                          │
│  18. OnRuntimeClose() - 运行时关闭通知                           │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 关键文件位置

| 组件 | 文件路径 |
|-----|---------|
| 安装入口 | `internal/service/install_plugin.go` |
| 安装器 | `internal/core/plugin_manager/installer.go` |
| 启动器 | `internal/core/control_panel/launcher_local.go` |
| 运行时构造 | `internal/core/local_runtime/constructor.go` |
| 环境初始化 | `internal/core/local_runtime/environment.go` |
| Python 环境 | `internal/core/local_runtime/environment_python.go` |
| 子进程管理 | `internal/core/local_runtime/subprocess.go` |
| 实例管理 | `internal/core/local_runtime/instance.go` |
| 调度控制 | `internal/core/local_runtime/control.go` |
| 会话管理 | `internal/core/session_manager/session.go` |

### 3.3 会话 (Session) 结构

```go
type Session struct {
    ID                     string
    TenantID               string
    UserID                 string
    PluginUniqueIdentifier plugin_entities.PluginUniqueIdentifier
    ClusterID              string

    InvokeFrom             access_types.PluginAccessType   // 调用来源类型
    Action                 access_types.PluginAccessAction // 具体操作
    Declaration            *plugin_entities.PluginDeclaration

    // 上下文信息
    ConversationID *string
    MessageID      *string
    AppID          *string
    EndpointID     *string
    Context        map[string]any

    // 运行时引用
    runtime             plugin_entities.PluginRuntimeSessionIOInterface
    backwardsInvocation dify_invocation.BackwardsInvocation
}
```

---

## 4. 钩子函数与回调机制

本节按运行时类型分类介绍各自的钩子函数和回调机制。

### 4.1 Local 运行时钩子

Local 运行时通过子进程管理插件，拥有最完整的生命周期钩子体系。

#### 4.1.1 实例级钩子 (PluginInstanceNotifier)

定义于 `internal/core/local_runtime/signals_instance.go`:

```go
type PluginInstanceNotifier interface {
    OnInstanceStarting()                              // 实例启动中
    OnInstanceReady(*PluginInstance)                  // 实例就绪
    OnInstanceLaunchFailed(*PluginInstance, error)    // 启动失败
    OnInstanceShutdown(*PluginInstance)               // 实例关闭
    OnInstanceHeartbeat(*PluginInstance)              // 收到心跳
    OnInstanceLog(*PluginInstance, PluginLogEvent)    // 插件日志
    OnInstanceErrorLog(*PluginInstance, error)        // 错误日志
    OnInstanceWarningLog(*PluginInstance, string)     // 警告日志
    OnInstanceStdout(*PluginInstance, []byte)         // 标准输出
    OnInstanceStderr(*PluginInstance, []byte)         // 标准错误
}
```

**触发时机**:

| 钩子 | 触发时机 | 用途 |
|-----|---------|------|
| `OnInstanceStarting` | 子进程启动前 | 日志记录、状态更新 |
| `OnInstanceReady` | 收到首次心跳后 | 标记实例可用、释放信号量 |
| `OnInstanceLaunchFailed` | 启动超时或进程退出 | 错误处理、重试逻辑 |
| `OnInstanceShutdown` | 实例停止时 | 清理资源、更新状态 |
| `OnInstanceHeartbeat` | 每次收到心跳 | 更新活跃时间戳 |
| `OnInstanceLog` | 插件输出日志事件 | 日志收集 |
| `OnInstanceErrorLog` | 插件输出错误 | 错误监控 |
| `OnInstanceWarningLog` | 心跳超时警告 | 健康检查 |
| `OnInstanceStdout` | stdout 有数据 | 数据处理、活跃检测 |
| `OnInstanceStderr` | stderr 有数据 | 错误收集 |

#### 4.1.2 运行时级钩子 (PluginRuntimeNotifier)

定义于 `internal/core/local_runtime/signals_runtime.go`:

```go
type PluginRuntimeNotifier interface {
    OnInstanceStarting()                        // 实例启动中
    OnInstanceReady(*PluginInstance)            // 实例就绪
    OnInstanceLaunchFailed(*PluginInstance, error)
    OnInstanceShutdown(*PluginInstance)
    OnInstanceLog(*PluginInstance, PluginLogEvent)
    OnInstanceScaleUp(int32)                    // 扩容通知
    OnInstanceScaleDown(int32)                  // 缩容通知
    OnInstanceScaleDownFailed(error)            // 缩容失败
    OnRuntimeStopSchedule()                     // 调度循环停止
    OnRuntimeClose()                            // 运行时完全关闭
}
```

**扩缩容钩子**:
- `OnInstanceScaleUp(count)`: 当实例数增加时触发，参数为新的实例总数
- `OnInstanceScaleDown(count)`: 当实例数减少时触发，参数为新的实例总数
- `OnInstanceScaleDownFailed(err)`: 缩容失败时触发

#### 4.1.3 控制面板钩子 (ControlPanelNotifier)

定义于 `internal/core/control_panel/signals.go`:

```go
type ControlPanelNotifier interface {
    // Local 运行时钩子
    OnLocalRuntimeStarting(identifier PluginUniqueIdentifier)
    OnLocalRuntimeReady(runtime *LocalPluginRuntime)
    OnLocalRuntimeStartFailed(identifier PluginUniqueIdentifier, err error)
    OnLocalRuntimeStop(runtime *LocalPluginRuntime)
    OnLocalRuntimeStopped(identifier PluginUniqueIdentifier)
    OnLocalRuntimeScaleUp(runtime *LocalPluginRuntime, newCount int32)
    OnLocalRuntimeScaleDown(runtime *LocalPluginRuntime, newCount int32)

    // Debug 运行时钩子
    OnDebuggingRuntimeConnected(runtime *RemotePluginRuntime)
    OnDebuggingRuntimeDisconnected(runtime *RemotePluginRuntime)
}
```

#### 4.1.4 Local 生命周期流程图

```
LaunchLocalPlugin()
    │
    ├─► OnLocalRuntimeStarting()
    │
    ▼
BuildRuntime() → InitEnvironment()
    │
    ▼
Schedule() → startNewInstance()
    │
    ├─► OnInstanceStarting()
    │
    ▼
Wait for Heartbeat (max 120s)
    │
    ├─[成功]─► OnInstanceReady() → OnLocalRuntimeReady()
    │
    └─[失败]─► OnInstanceLaunchFailed() → OnLocalRuntimeStartFailed()

运行中:
    │
    ├─► OnInstanceHeartbeat() (每次心跳)
    ├─► OnInstanceLog() (日志事件)
    ├─► OnInstanceStdout/Stderr() (IO 事件)
    │
    ▼
GracefulStop() / Stop()
    │
    ├─► OnLocalRuntimeStop()
    ├─► OnRuntimeStopSchedule()
    │
    ▼
For each instance: OnInstanceShutdown()
    │
    ▼
OnRuntimeClose() → OnLocalRuntimeStopped()
```

---

### 4.2 Remote/Debug 运行时钩子

Remote 运行时通过 TCP 连接管理插件，主要用于开发调试。

#### 4.2.1 服务器级钩子 (PluginRuntimeNotifier)

定义于 `internal/core/debugging_runtime/server_signals.go`:

```go
type PluginRuntimeNotifier interface {
    OnRuntimeConnected(*RemotePluginRuntime) error  // 插件连接成功
    OnRuntimeDisconnected(*RemotePluginRuntime)     // 插件断开连接
    OnServerShutdown(reason ServerShutdownReason)   // 服务器关闭
}
```

**服务器关闭原因**:
```go
type ServerShutdownReason string

const (
    SERVER_SHUTDOWN_REASON_EXIT  = "exit"   // 正常退出
    SERVER_SHUTDOWN_REASON_ERROR = "error"  // 错误退出
)
```

#### 4.2.2 gnet 事件钩子

定义于 `internal/core/debugging_runtime/hooks.go`:

| gnet 钩子 | 触发时机 | 内部处理 |
|----------|---------|---------|
| `OnBoot` | TCP 服务器启动 | 初始化 |
| `OnOpen` | 新 TCP 连接建立 | 创建 `RemotePluginRuntime`，设置 10 秒握手超时 |
| `OnClose` | TCP 连接关闭 | 调用 `cleanupResources()`，触发 `OnRuntimeDisconnected` |
| `OnTraffic` | 收到数据 | 解码消息，路由到 `onMessage()` |
| `OnShutdown` | 服务器关闭 | 触发 `OnServerShutdown(SERVER_SHUTDOWN_REASON_EXIT)` |

#### 4.2.3 握手阶段注册事件

定义于 `internal/core/debugging_runtime/type.go`:

```go
type RegisterEventType string

const (
    REGISTER_EVENT_TYPE_HAND_SHAKE                = "hand_shake"
    REGISTER_EVENT_TYPE_ASSET_CHUNK               = "asset_chunk"
    REGISTER_EVENT_TYPE_MANIFEST_DECLARATION      = "manifest_declaration"
    REGISTER_EVENT_TYPE_TOOL_DECLARATION          = "tool_declaration"
    REGISTER_EVENT_TYPE_MODEL_DECLARATION         = "model_declaration"
    REGISTER_EVENT_TYPE_ENDPOINT_DECLARATION      = "endpoint_declaration"
    REGISTER_EVENT_TYPE_AGENT_STRATEGY_DECLARATION = "agent_strategy_declaration"
    REGISTER_EVENT_TYPE_DATASOURCE_DECLARATION    = "datasource_declaration"
    REGISTER_EVENT_TYPE_TRIGGER_DECLARATION       = "trigger_declaration"
    REGISTER_EVENT_TYPE_END                       = "end"
)
```

#### 4.2.4 Remote 生命周期流程图

```
TCP Client Connect
    │
    ▼
OnOpen() → 创建 RemotePluginRuntime
    │
    ├─► 10 秒握手超时计时器
    │
    ▼
OnTraffic() → onMessage()
    │
    ├─► REGISTER_EVENT_TYPE_HAND_SHAKE
    │       └─► handleHandleShake()
    │
    ├─► REGISTER_EVENT_TYPE_ASSET_CHUNK
    │       └─► handleAssetChunk()
    │
    ├─► REGISTER_EVENT_TYPE_*_DECLARATION
    │       └─► handleDeclarationRegister()
    │
    └─► REGISTER_EVENT_TYPE_END
            │
            ├─► 标记 initialized = true
            ├─► OnRuntimeConnected()
            └─► SpawnCore() 启动消息处理循环

运行中:
    │
    ├─► OnTraffic() → 解析事件 → 路由到会话回调
    │
    ▼
TCP 断开 / 心跳超时 (60s)
    │
    ▼
OnClose()
    │
    ├─► cleanupResources()
    ├─► 关闭所有会话监听器
    └─► OnRuntimeDisconnected()
```

#### 4.2.5 心跳监控

定义于 `internal/core/debugging_runtime/lifetime.go`:

```go
func (r *RemotePluginRuntime) HeartbeatMonitor() {
    // 每 60 秒检查一次
    // 如果超过 60 秒无活动，关闭连接
}
```

---

### 4.3 Serverless 运行时钩子

Serverless 运行时是无状态的 HTTP 调用模式，**不实现传统的 Notifier 模式**。

#### 4.3.1 特点

- **无持久连接**: 每次调用都是独立的 HTTP 请求
- **无实例管理**: 不维护长期运行的进程
- **无扩缩容钩子**: 由云平台自动管理
- **不支持反向调用**: `SESSION_MESSAGE_TYPE_INVOKE` 被拒绝

#### 4.3.2 会话事件回调

Serverless 使用回调函数而非接口模式处理事件。

定义于 `internal/core/serverless_runtime/io.go`:

```go
// Listen 创建会话监听器
func (r *ServerlessPluginRuntime) Listen(sessionId string) (
    *entities.Broadcast[plugin_entities.SessionMessage],
    error,
)

// Write 发送请求并处理响应
func (r *ServerlessPluginRuntime) Write(
    sessionId string,
    action access_types.PluginAccessAction,
    data []byte,
) error
```

**Write 方法内部回调** (行 97-125):

```go
plugin_entities.ParsePluginUniversalEvent(
    eventBytes,
    statusText,
    // 1. 会话消息回调
    func(sessionId string, data []byte) {
        // 解析并发送到监听器
        l.Send(sessionMessage)
    },
    // 2. 心跳回调 (空实现)
    func() {},
    // 3. 错误回调
    func(err string) {
        l.Send(plugin_entities.SessionMessage{
            Type: plugin_entities.SESSION_MESSAGE_TYPE_ERROR,
            Data: []byte(err),
        })
    },
    // 4. 日志回调 (空实现)
    func(logEvent plugin_entities.PluginLogEvent) {},
)
```

#### 4.3.3 Serverless 事务处理器

定义于 `internal/core/io_tunnel/backwards_invocation/transaction/serverless_handler.go`:

```go
type ServerlessTransactionHandler struct {
    maxTimeout time.Duration
}

// Handle 处理 Serverless 请求
func (h *ServerlessTransactionHandler) Handle(ctx *gin.Context, sessionId string)
```

**事务写入器** (定义于 `serverless_writer.go`):

```go
type ServerlessTransactionWriter struct {
    session          *session_manager.Session
    writeFlushCloser WriteFlushCloser
}

// Write 写入事件并 flush
func (w *ServerlessTransactionWriter) Write(
    event session_manager.PLUGIN_IN_STREAM_EVENT,
    data any,
) error

// Done 关闭写入器
func (w *ServerlessTransactionWriter) Done()
```

#### 4.3.4 Serverless 生命周期流程图

```
HTTP POST /invoke?action=xxx
    │
    ▼
ServerlessPluginRuntime.Listen(sessionId)
    │
    └─► 创建 Broadcast[SessionMessage]

ServerlessPluginRuntime.Write(sessionId, action, data)
    │
    ├─► 异步提交请求任务
    │       │
    │       ▼
    │   HTTP POST → Lambda Function
    │       │
    │       ▼
    │   bufio.Scanner 读取 SSE 响应
    │       │
    │       ├─► ParsePluginUniversalEvent()
    │       │       │
    │       │       ├─► sessionHandler → l.Send(message)
    │       │       ├─► errorHandler → l.Send(error)
    │       │       └─► heartbeat/log (忽略)
    │       │
    │       └─► 响应结束
    │               │
    │               ├─► l.Send(SESSION_MESSAGE_TYPE_END)
    │               ├─► l.Close()
    │               └─► listeners.Delete(sessionId)
    │
    └─► 返回 nil (异步处理)

监听器读取:
    │
    ▼
Broadcast.Listen(callback)
    │
    └─► callback(SessionMessage) 被调用
```

#### 4.3.5 Serverless 限制

| 功能 | 支持情况 | 说明 |
|-----|---------|------|
| 工具调用 | ✅ | 通过 HTTP 请求 |
| 模型调用 | ✅ | 通过 HTTP 请求 |
| 反向调用 | ❌ | 明确拒绝，返回 `serverless_event_not_supported` |
| 心跳监控 | ❌ | 无状态，无需心跳 |
| 实例扩缩容 | ❌ | 由云平台管理 |
| 日志收集 | ❌ | 日志回调为空实现 |

**反向调用拒绝逻辑** (定义于 `internal/core/io_tunnel/generic.go`):

```go
case plugin_entities.SESSION_MESSAGE_TYPE_INVOKE:
    if session.Runtime().Type() == plugin_entities.PLUGIN_RUNTIME_TYPE_SERVERLESS {
        response.Write(InvokePluginResponse[T]{
            Event:   "serverless_event_not_supported",
            Message: "serverless event is not supported by full duplex",
        })
        return
    }
    // ... 处理反向调用
```

---

### 4.4 三种运行时钩子对比

| 钩子类别 | Local | Remote/Debug | Serverless |
|---------|-------|--------------|------------|
| **实例启动** | `OnInstanceStarting` | `OnOpen` | N/A |
| **实例就绪** | `OnInstanceReady` | `OnRuntimeConnected` | N/A |
| **实例失败** | `OnInstanceLaunchFailed` | 握手超时关闭 | HTTP 错误 |
| **实例关闭** | `OnInstanceShutdown` | `OnClose` | 请求结束 |
| **心跳监控** | `OnInstanceHeartbeat` | `HeartbeatMonitor` | N/A |
| **日志事件** | `OnInstanceLog` | 事件解析 | 忽略 |
| **错误事件** | `OnInstanceErrorLog` | 事件解析 | 回调处理 |
| **扩缩容** | `OnInstanceScaleUp/Down` | N/A | 云平台管理 |
| **运行时关闭** | `OnRuntimeClose` | `OnServerShutdown` | N/A |
| **反向调用** | ✅ 支持 | ✅ 支持 | ❌ 不支持 |

---

### 4.5 反向调用 (Backwards Invocation)

插件可以通过反向调用机制访问 Dify API 服务。

**注意**: Serverless 运行时不支持反向调用，仅 Local 和 Remote/Debug 运行时支持。

#### 4.5.1 支持的调用类型

定义于 `internal/core/dify_invocation/types.go`:

| 调用类型 | 说明 | 所需权限 |
|---------|------|---------|
| `llm` | LLM 模型调用 | `AllowInvokeLLM()` |
| `llm_structured_output` | 结构化输出 | `AllowInvokeLLM()` |
| `text_embedding` | 文本向量化 | `AllowInvokeTextEmbedding()` |
| `multimodal_embedding` | 多模态向量化 | `AllowInvokeTextEmbedding()` |
| `rerank` | 重排序 | `AllowInvokeRerank()` |
| `multimodal_rerank` | 多模态重排序 | `AllowInvokeRerank()` |
| `tts` | 文本转语音 | `AllowInvokeTTS()` |
| `speech2text` | 语音转文本 | `AllowInvokeSpeech2Text()` |
| `moderation` | 内容审核 | `AllowInvokeModeration()` |
| `tool` | 工具调用 | `AllowInvokeTool()` |
| `app` | 应用调用 | `AllowInvokeApp()` |
| `node_parameter_extractor` | 参数提取 | `AllowInvokeNode()` |
| `node_question_classifier` | 问题分类 | `AllowInvokeNode()` |
| `storage` | 存储操作 | `AllowInvokeStorage()` |
| `upload_file` | 文件上传 | 始终允许 |
| `fetch_app` | 获取应用信息 | `AllowInvokeApp()` |

#### 4.5.2 反向调用流程

```
Plugin Process
    │
    ▼ (发送 SESSION_MESSAGE_TYPE_INVOKE)
Plugin Runtime
    │
    ▼
Session Manager
    │
    ▼ (路由到) BackwardsInvocation.InvokeDify()
    │
    ├─► Permission Check (检查 manifest 权限)
    │       │
    │       └─► 拒绝? WriteError() → 返回插件
    │
    ├─► Async Task Dispatch (异步分发)
    │       │
    │       ▼
    │   具体执行器 (如 executeDifyInvocationLLMTask)
    │       │
    │       ▼
    │   HTTP Client → Dify API Server
    │       │
    │       ▼ (流式/结构化响应)
    │   handle.WriteResponse()
    │       │
    │       ▼
    │   Transaction Writer → 返回插件
```

#### 4.5.3 BackwardsInvocation 接口

```go
type BackwardsInvocation interface {
    InvokeLLM(payload *InvokeLLMRequest) (*stream.Stream[LLMResultChunk], error)
    InvokeLLMWithStructuredOutput(...) (*stream.Stream[...], error)
    InvokeTextEmbedding(payload *InvokeTextEmbeddingRequest) (*TextEmbeddingResult, error)
    InvokeMultimodalEmbedding(...) (*MultimodalEmbeddingResult, error)
    InvokeRerank(payload *InvokeRerankRequest) (*RerankResult, error)
    InvokeMultimodalRerank(...) (*MultimodalRerankResult, error)
    InvokeTTS(payload *InvokeTTSRequest) (*stream.Stream[TTSResult], error)
    InvokeSpeech2Text(payload *InvokeSpeech2TextRequest) (*Speech2TextResult, error)
    InvokeModeration(payload *InvokeModerationRequest) (*ModerationResult, error)
    InvokeTool(payload *InvokeToolRequest) (*stream.Stream[ToolResponseChunk], error)
    InvokeApp(payload *InvokeAppRequest) (*stream.Stream[map[string]any], error)
    InvokeParameterExtractor(...) (*InvokeNodeResponse, error)
    InvokeQuestionClassifier(...) (*InvokeNodeResponse, error)
    InvokeEncrypt(payload *InvokeEncryptRequest) (map[string]any, error)
    InvokeSummary(payload *InvokeSummaryRequest) (*InvokeSummaryResponse, error)
    UploadFile(payload *UploadFileRequest) (*UploadFileResponse, error)
    FetchApp(payload *FetchAppRequest) (map[string]any, error)
}
```

### 4.6 插件事件类型

定义于 `pkg/entities/plugin_entities/event.go`:

```go
// 插件输出事件
const (
    PLUGIN_EVENT_LOG       = "log"       // 日志事件
    PLUGIN_EVENT_SESSION   = "session"   // 会话消息
    PLUGIN_EVENT_ERROR     = "error"     // 错误事件
    PLUGIN_EVENT_HEARTBEAT = "heartbeat" // 心跳事件
)

// 会话消息类型
const (
    SESSION_MESSAGE_TYPE_STREAM = "stream" // 流式响应
    SESSION_MESSAGE_TYPE_END    = "end"    // 结束标记
    SESSION_MESSAGE_TYPE_ERROR  = "error"  // 错误消息
    SESSION_MESSAGE_TYPE_INVOKE = "invoke" // 反向调用
)
```

---

## 5. 变量约定与配置

### 5.1 环境变量

完整配置参考 `.env.example`，主要分类：

#### 服务器配置
```bash
SERVER_HOST=0.0.0.0
SERVER_PORT=5002
SERVER_KEY=<security-key>
GIN_MODE=release
```

#### Dify 内部 API
```bash
DIFY_INNER_API_KEY="<api-key>"
DIFY_INNER_API_URL=http://127.0.0.1:5001
DIFY_INVOCATION_CONNECTION_IDLE_TIMEOUT=120
DIFY_BACKWARDS_INVOCATION_WRITE_TIMEOUT=5000
DIFY_BACKWARDS_INVOCATION_READ_TIMEOUT=240000
```

#### 插件远程安装
```bash
PLUGIN_REMOTE_INSTALLING_ENABLED=true
PLUGIN_REMOTE_INSTALLING_HOST=127.0.0.1
PLUGIN_REMOTE_INSTALLING_PORT=5003
```

#### 存储配置
```bash
PLUGIN_STORAGE_TYPE=local           # local / s3 / tencent-cos / aliyun-oss / azure / gcs / huawei-obs / volcengine-tos
PLUGIN_STORAGE_LOCAL_ROOT=./storage
PLUGIN_INSTALLED_PATH=plugin
PLUGIN_WORKING_PATH=cwd
```

#### Redis 配置
```bash
REDIS_HOST=127.0.0.1
REDIS_PORT=6379
REDIS_PASSWORD=difyai123456
REDIS_DB=0
REDIS_USE_SSL=false
```

#### 数据库配置
```bash
DB_TYPE=postgresql
DB_USERNAME=postgres
DB_PASSWORD=difyai123456
DB_HOST=localhost
DB_PORT=5432
DB_DATABASE=dify_plugin
```

#### 插件运行时
```bash
PYTHON_INTERPRETER_PATH=/usr/bin/python3
UV_PATH=
PYTHON_ENV_INIT_TIMEOUT=120
PLUGIN_RUNTIME_BUFFER_SIZE=1024
PLUGIN_RUNTIME_MAX_BUFFER_SIZE=5242880
```

#### 安全配置
```bash
FORCE_VERIFYING_SIGNATURE=true
ENFORCE_LANGGENIUS_PLUGIN_SIGNATURES=true
MAX_PLUGIN_PACKAGE_SIZE=52428800
```

### 5.2 插件唯一标识符格式

```
格式: author/plugin_id:version@checksum

示例:
- langgenius/my_tool:1.0.0@abc123def456...
- partner-name/api_plugin:2.1.3-beta@xyz789...

规则:
- Author: 1-64 字符, 字母数字/下划线/连字符
- Plugin ID: 1-255 字符, 字母数字/下划线/连字符
- Version: 语义化版本 (如 1.0.0, 2.1.3-beta)
- Checksum: 32-64 位十六进制字符串 (SHA256)
```

### 5.3 HTTP 请求头常量

```go
const (
    X_PLUGIN_ID     = "X-Plugin-ID"      // 插件 ID
    X_API_KEY       = "X-Api-Key"        // API 密钥
    X_ADMIN_API_KEY = "X-Admin-Api-Key"  // 管理员 API 密钥
)
```

---

## 6. 各类型插件详解

### 6.1 Tool 插件

**用途**: 提供可复用的工具函数，可被 Agent 或工作流调用。

**声明文件位置**: `pkg/entities/plugin_entities/tool_declaration.go`

#### 6.1.1 声明结构

```go
type ToolProviderDeclaration struct {
    Identity          ToolProviderIdentity   // 提供者身份
    CredentialsSchema []ProviderConfig       // 凭证配置 (可选)
    OAuthSchema       *OAuthSchema           // OAuth 配置 (可选)
    Tools             []ToolDeclaration      // 工具列表 (必需)
}

type ToolDeclaration struct {
    Identity             ToolIdentity          // 工具身份
    Description          ToolDescription       // 描述 (必需)
    Parameters           []ToolParameter       // 参数列表
    OutputSchema         map[string]any        // 输出结构
    HasRuntimeParameters bool                  // 是否有运行时参数
}
```

#### 6.1.2 参数类型

```go
const (
    TOOL_PARAMETER_TYPE_STRING         = "string"
    TOOL_PARAMETER_TYPE_NUMBER         = "number"
    TOOL_PARAMETER_TYPE_BOOLEAN        = "boolean"
    TOOL_PARAMETER_TYPE_SELECT         = "select"
    TOOL_PARAMETER_TYPE_SECRET_INPUT   = "secret-input"
    TOOL_PARAMETER_TYPE_FILE           = "file"
    TOOL_PARAMETER_TYPE_FILES          = "files"
    TOOL_PARAMETER_TYPE_APP_SELECTOR   = "app-selector"
    TOOL_PARAMETER_TYPE_MODEL_SELECTOR = "model-selector"
    TOOL_PARAMETER_TYPE_ANY            = "any"
    TOOL_PARAMETER_TYPE_DYNAMIC_SELECT = "dynamic-select"
    TOOL_PARAMETER_ARRAY               = "array"
    TOOL_PARAMETER_OBJECT              = "object"
    TOOL_PARAMETER_TYPE_CHECKBOX       = "checkbox"
)
```

#### 6.1.3 参数表单类型

```go
const (
    TOOL_PARAMETER_FORM_SCHEMA = "schema" // Schema 定义
    TOOL_PARAMETER_FORM_FORM   = "form"   // 表单输入
    TOOL_PARAMETER_FORM_LLM    = "llm"    // LLM 填充
)
```

#### 6.1.4 请求/响应

```go
// 调用请求
type RequestInvokeTool struct {
    Provider       string         `json:"provider"`
    Tool           string         `json:"tool"`
    ToolParameters map[string]any `json:"tool_parameters"`
    Credentials    map[string]any `json:"credentials"`
}

// 凭证验证请求
type RequestValidateToolCredentials struct {
    Provider    string         `json:"provider"`
    Credentials map[string]any `json:"credentials"`
}
```

#### 6.1.5 访问操作

| 操作 | 说明 |
|-----|------|
| `invoke_tool` | 调用工具 |
| `validate_tool_credentials` | 验证凭证 |
| `get_tool_runtime_parameters` | 获取运行时参数 |

---

### 6.2 Model 插件

**用途**: 提供 AI 模型能力，包括 LLM、Embedding、TTS 等。

**声明文件位置**: `pkg/entities/plugin_entities/model_declaration.go`

#### 6.2.1 声明结构

```go
type ModelProviderDeclaration struct {
    Provider                 string                          // 提供者名称 (必需)
    Label                    I18nObject                      // 标签
    Description              I18nObject                      // 描述
    SupportedModelTypes      []ModelType                     // 支持的模型类型
    ConfigurateMethods       []ModelProviderConfigurateMethod // 配置方法
    ProviderCredentialSchema *CredentialSchema               // 提供者凭证
    ModelCredentialSchema    *CredentialSchema               // 模型凭证
    Models                   []ModelDeclaration              // 模型列表
}

type ModelDeclaration struct {
    Model           string                 // 模型标识 (必需)
    Label           I18nObject             // 标签
    ModelType       ModelType              // 模型类型 (必需)
    Features        []string               // 特性列表
    FetchFrom       string                 // 配置方法
    ModelProperties map[string]any         // 模型属性
    Deprecated      bool                   // 是否废弃
    ParameterRules  []ModelParameterRule   // 参数规则
    PriceConfig     *PriceConfig           // 定价配置
}
```

#### 6.2.2 模型类型

```go
const (
    MODEL_TYPE_LLM                  = "llm"                  // 语言模型
    MODEL_TYPE_TEXT_EMBEDDING       = "text-embedding"       // 文本向量化
    MODEL_TYPE_RERANKING            = "rerank"               // 重排序
    MODEL_TYPE_SPEECH2TEXT          = "speech2text"          // 语音转文本
    MODEL_TYPE_MODERATION           = "moderation"           // 内容审核
    MODEL_TYPE_TTS                  = "tts"                  // 文本转语音
    MODEL_TYPE_TEXT2IMG             = "text2img"             // 文本生成图片
    MODEL_TYPE_MULTIMODAL_EMBEDDING = "multimodal-embedding" // 多模态向量化
    MODEL_TYPE_MULTIMODAL_RERANK    = "multimodal-rerank"    // 多模态重排序
)
```

#### 6.2.3 配置方法

```go
const (
    CONFIGURATE_METHOD_PREDEFINED_MODEL   = "predefined-model"   // 预定义模型
    CONFIGURATE_METHOD_CUSTOMIZABLE_MODEL = "customizable-model" // 可自定义模型
)
```

#### 6.2.4 参数类型

```go
const (
    PARAMETER_TYPE_FLOAT   = "float"
    PARAMETER_TYPE_INT     = "int"
    PARAMETER_TYPE_STRING  = "string"
    PARAMETER_TYPE_BOOLEAN = "boolean"
    PARAMETER_TYPE_TEXT    = "text"
)
```

#### 6.2.5 请求示例

```go
// LLM 调用
type RequestInvokeLLM struct {
    Provider        string              `json:"provider"`
    Model           string              `json:"model"`
    ModelParameters map[string]any      `json:"model_parameters"`
    PromptMessages  []PromptMessage     `json:"prompt_messages"`
    Tools           []PromptMessageTool `json:"tools"`
    Stop            []string            `json:"stop"`
    Stream          bool                `json:"stream"`
    Credentials     map[string]any      `json:"credentials"`
}

// Text Embedding
type RequestInvokeTextEmbedding struct {
    Provider    string         `json:"provider"`
    Model       string         `json:"model"`
    Credentials map[string]any `json:"credentials"`
    Texts       []string       `json:"texts"`
    InputType   string         `json:"input_type"`
}
```

---

### 6.3 Agent Strategy 插件

**用途**: 提供 Agent 推理策略，控制 Agent 的行为逻辑。

**声明文件位置**: `pkg/entities/plugin_entities/agent_declaration.go`

#### 6.3.1 声明结构

```go
type AgentStrategyProviderDeclaration struct {
    Identity   AgentStrategyProviderIdentity   // 提供者身份
    Strategies []AgentStrategyDeclaration      // 策略列表 (必需)
}

type AgentStrategyDeclaration struct {
    Identity     AgentStrategyIdentity      // 策略身份
    Description  I18nObject                 // 描述 (必需)
    Parameters   []AgentStrategyParameter   // 参数列表
    OutputSchema map[string]any             // 输出结构
    Features     []string                   // 特性列表
}
```

#### 6.3.2 参数类型

```go
const (
    AGENT_STRATEGY_PARAMETER_TYPE_STRING         = "string"
    AGENT_STRATEGY_PARAMETER_TYPE_NUMBER         = "number"
    AGENT_STRATEGY_PARAMETER_TYPE_BOOLEAN        = "boolean"
    AGENT_STRATEGY_PARAMETER_TYPE_SELECT         = "select"
    AGENT_STRATEGY_PARAMETER_TYPE_SECRET_INPUT   = "secret-input"
    AGENT_STRATEGY_PARAMETER_TYPE_FILE           = "file"
    AGENT_STRATEGY_PARAMETER_TYPE_FILES          = "files"
    AGENT_STRATEGY_PARAMETER_TYPE_APP_SELECTOR   = "app-selector"
    AGENT_STRATEGY_PARAMETER_TYPE_MODEL_SELECTOR = "model-selector"
    AGENT_STRATEGY_PARAMETER_TYPE_TOOLS_SELECTOR = "array[tools]"  // Agent 特有
    AGENT_STRATEGY_PARAMETER_TYPE_ANY            = "any"
)
```

**特别说明**: Agent Strategy 支持 `TOOLS_SELECTOR` 类型，允许选择可用工具。

#### 6.3.3 请求示例

```go
type RequestInvokeAgentStrategy struct {
    AgentStrategyProvider string         `json:"agent_strategy_provider"`
    AgentStrategy         string         `json:"agent_strategy"`
    AgentStrategyParams   map[string]any `json:"agent_strategy_params"`
}
```

---

### 6.4 Datasource 插件

**用途**: 提供数据源连接能力，支持网站爬取、在线文档、云盘等。

**声明文件位置**: `pkg/entities/plugin_entities/datasource_declaration.go`

#### 6.4.1 声明结构

```go
type DatasourceProviderDeclaration struct {
    Identity          DatasourceProviderIdentity // 提供者身份
    CredentialsSchema []ProviderConfig           // 凭证配置 (可选)
    OAuthSchema       *OAuthSchema               // OAuth 配置 (可选)
    ProviderType      DatasourceType             // 数据源类型 (必需)
    Datasources       []DatasourceDeclaration    // 数据源列表
}

type DatasourceDeclaration struct {
    Identity     DatasourceIdentity     // 数据源身份
    Parameters   []DatasourceParameter  // 参数列表 (必需, min=1)
    Description  I18nObject             // 描述 (必需)
    OutputSchema map[string]any         // 输出结构
}
```

#### 6.4.2 数据源类型

```go
const (
    DatasourceTypeWebsiteCrawl   = "website_crawl"   // 网站爬取
    DatasourceTypeOnlineDocument = "online_document" // 在线文档
    DatasourceTypeOnlineDrive    = "online_drive"    // 云盘
)
```

#### 6.4.3 参数类型

```go
const (
    DATASOURCE_PARAMETER_TYPE_STRING       = "string"
    DATASOURCE_PARAMETER_TYPE_NUMBER       = "number"
    DATASOURCE_PARAMETER_TYPE_BOOLEAN      = "boolean"
    DATASOURCE_PARAMETER_TYPE_SELECT       = "select"
    DATASOURCE_PARAMETER_TYPE_SECRET_INPUT = "secret-input"
)
```

#### 6.4.4 请求示例

```go
// 调用数据源
type RequestInvokeDatasourceRequest struct {
    Provider             string         `json:"provider"`
    Datasource           string         `json:"datasource"`
    Credentials          map[string]any `json:"credentials"`
    DatasourceParameters map[string]any `json:"datasource_parameters"`
}

// 浏览云盘文件
type DatasourceOnlineDriveBrowseFilesRequest struct {
    Bucket             *string                `json:"bucket"`
    Prefix             string                 `json:"prefix"`
    MaxKeys            int                    `json:"max_keys"`
    NextPageParameters map[string]interface{} `json:"next_page_parameters"`
}
```

---

### 6.5 Trigger 插件

**用途**: 提供事件触发能力，支持 Webhook 订阅和事件派发。

**声明文件位置**: `pkg/entities/plugin_entities/trigger_declaration.go`

#### 6.5.1 声明结构

```go
type TriggerProviderDeclaration struct {
    Identity                TriggerProviderIdentity // 提供者身份
    SubscriptionSchema      []ProviderConfig        // 订阅参数 (必需)
    SubscriptionConstructor *SubscriptionConstructor // 订阅构造器 (可选)
    Events                  []EventDeclaration       // 事件列表
}

type EventDeclaration struct {
    Identity     EventIdentity     // 事件身份
    Parameters   []EventParameter  // 参数列表
    Description  I18nObject        // 描述 (必需)
    OutputSchema map[string]any    // 输出结构
}

type TriggerRuntime struct {
    Credentials map[string]any `json:"credentials"`
    SessionID   *string        `json:"session_id"`
}
```

#### 6.5.2 事件参数类型

```go
const (
    EVENT_PARAMETER_TYPE_STRING         = "string"
    EVENT_PARAMETER_TYPE_NUMBER         = "number"
    EVENT_PARAMETER_TYPE_BOOLEAN        = "boolean"
    EVENT_PARAMETER_TYPE_SELECT         = "select"
    EVENT_PARAMETER_TYPE_FILE           = "file"
    EVENT_PARAMETER_TYPE_FILES          = "files"
    EVENT_PARAMETER_TYPE_MODEL_SELECTOR = "model-selector"
    EVENT_PARAMETER_TYPE_APP_SELECTOR   = "app-selector"
    EVENT_PARAMETER_TYPE_OBJECT         = "object"
    EVENT_PARAMETER_TYPE_ARRAY          = "array"
    EVENT_PARAMETER_TYPE_DYNAMIC_SELECT = "dynamic-select"
    EVENT_PARAMETER_TYPE_CHECKBOX       = "checkbox"
)
```

#### 6.5.3 请求示例

```go
// 订阅触发器
type TriggerSubscribeRequest struct {
    Provider    string         `json:"provider"`
    Endpoint    string         `json:"endpoint"`
    Parameters  map[string]any `json:"parameters"`
    Credentials map[string]any `json:"credentials"`
}

// 取消订阅
type TriggerUnsubscribeRequest struct {
    Provider     string         `json:"provider"`
    Subscription map[string]any `json:"subscription"` // 必需
    Credentials  map[string]any `json:"credentials"`
}

// 调用事件
type TriggerInvokeEventRequest struct {
    Provider       string         `json:"provider"`
    Event          string         `json:"event"`
    RawHTTPRequest string         `json:"raw_http_request"`
    Parameters     map[string]any `json:"parameters"`
    Subscription   map[string]any `json:"subscription"` // 必需
    Payload        map[string]any `json:"payload"`
    Credentials    map[string]any `json:"credentials"`
}

// 派发事件
type TriggerDispatchEventRequest struct {
    Provider       string         `json:"provider"`
    Subscription   map[string]any `json:"subscription"` // 必需
    RawHTTPRequest string         `json:"raw_http_request"`
    Credentials    map[string]any `json:"credentials"`
}
```

#### 6.5.4 响应结构

```go
// 事件调用响应
type TriggerInvokeEventResponse struct {
    Variables map[string]any `json:"variables"`
    Cancelled bool           `json:"cancelled"`
}

// 事件派发响应
type TriggerDispatchEventResponse struct {
    UserID   string         `json:"user_id"`
    Events   []string       `json:"events"`
    Payload  map[string]any `json:"payload"`
    Response string         `json:"response"`
}

// 订阅响应
type TriggerSubscribeResponse struct {
    Subscription map[string]any `json:"subscription"`
}
```

---

### 6.6 Endpoint 插件

**用途**: 提供 HTTP 端点扩展，支持自定义 API 路由。

**声明文件位置**: `pkg/entities/plugin_entities/endpoint_declaration.go`

#### 6.6.1 声明结构

```go
type EndpointProviderDeclaration struct {
    Settings      []ProviderConfig      `json:"settings"`  // 配置项 (可选)
    Endpoints     []EndpointDeclaration `json:"endpoints"` // 端点列表
    EndpointFiles []string              `json:"endpoint_files"` // 端点定义文件
}

type EndpointDeclaration struct {
    Path   string         `json:"path"`   // URL 路径 (必需)
    Method EndpointMethod `json:"method"` // HTTP 方法 (必需)
    Hidden bool           `json:"hidden"` // 是否隐藏
}
```

#### 6.6.2 支持的 HTTP 方法

```go
const (
    EndpointMethodHead    = "HEAD"
    EndpointMethodGet     = "GET"
    EndpointMethodPost    = "POST"
    EndpointMethodPut     = "PUT"
    EndpointMethodDelete  = "DELETE"
    EndpointMethodOptions = "OPTIONS"
)
```

#### 6.6.3 请求示例

```go
type RequestInvokeEndpoint struct {
    RawHttpRequest string         `json:"raw_http_request"` // Hex 编码的原始请求
    Settings       map[string]any `json:"settings"`
}
```

---

## 7. 插件目录结构

本节介绍各类型插件的标准目录结构，方便开发者参考。

### 7.1 Tool 插件

```
plugin-name/
├── manifest.yaml                    # 插件清单
├── README.md                        # 说明文档
├── pyproject.toml                   # Python 依赖 (uv)
├── _assets/
│   └── icon.svg                     # 插件图标
├── provider/
│   ├── {provider_name}.yaml         # Provider 声明（包含凭证配置）
│   └── {provider_name}.py           # Provider 实现（凭证验证逻辑）
└── tools/
    ├── {tool_name}.yaml             # Tool 声明（参数定义）
    └── {tool_name}.py               # Tool 实现（invoke 方法）
```

**manifest.yaml 配置：**
```yaml
plugins:
  tools:
    - provider/{provider_name}.yaml
```

---

### 7.2 Model 插件

```
plugin-name/
├── manifest.yaml
├── README.md
├── pyproject.toml
├── _assets/
│   └── icon.svg
├── provider/
│   ├── {provider_name}.yaml         # Provider 声明
│   └── {provider_name}.py           # Provider 实现
└── models/
    ├── llm/                         # 大语言模型
    │   ├── llm.yaml
    │   └── llm.py
    ├── text_embedding/              # 文本嵌入模型
    │   ├── text_embedding.yaml
    │   └── text_embedding.py
    ├── rerank/                       # 重排序模型
    │   ├── rerank.yaml
    │   └── rerank.py
    ├── tts/                          # 文本转语音
    │   ├── tts.yaml
    │   └── tts.py
    ├── speech2text/                  # 语音转文本
    │   ├── speech2text.yaml
    │   └── speech2text.py
    └── moderation/                   # 内容审核模型
        ├── moderation.yaml
        └── moderation.py
```

**manifest.yaml 配置：**
```yaml
plugins:
  models:
    - provider/{provider_name}.yaml
```

**注意**：不需要所有模型类型，按需创建对应子目录。

---

### 7.3 Extension/Endpoint 插件

```
plugin-name/
├── manifest.yaml
├── README.md
├── pyproject.toml
├── _assets/
│   └── icon.svg
├── group/
│   └── {group_name}.yaml            # Endpoint 分组声明
└── endpoints/
    ├── {endpoint_name}.yaml         # Endpoint 声明（路由配置）
    └── {endpoint_name}.py           # Endpoint 实现（HTTP 处理）
```

**manifest.yaml 配置：**
```yaml
plugins:
  endpoints:
    - group/{group_name}.yaml
```

---

### 7.4 Agent Strategy 插件

```
plugin-name/
├── manifest.yaml
├── README.md
├── pyproject.toml
├── _assets/
│   └── icon.svg
├── provider/
│   └── {provider_name}.yaml         # Provider 声明
└── strategies/
    ├── {strategy_name}.yaml         # Strategy 声明（参数定义）
    └── {strategy_name}.py           # Strategy 实现
```

**manifest.yaml 配置：**
```yaml
plugins:
  agent_strategies:
    - provider/{provider_name}.yaml
```

---

### 7.5 Datasource 插件

```
plugin-name/
├── manifest.yaml
├── README.md
├── pyproject.toml
├── _assets/
│   └── icon.svg
├── provider/
│   └── {provider_name}.yaml         # Provider 声明
└── datasources/
    ├── {datasource_name}.yaml       # Datasource 声明
    └── {datasource_name}.py         # Datasource 实现（Retrieve/RetrieveMany）
```

**manifest.yaml 配置：**
```yaml
plugins:
  datasources:
    - provider/{provider_name}.yaml
```

---

### 7.6 Trigger 插件

```
plugin-name/
├── manifest.yaml
├── README.md
├── pyproject.toml
├── _assets/
│   └── icon.svg
├── provider/
│   ├── {provider_name}.yaml         # Provider 声明
│   └── {provider_name}.py           # Provider 实现（Start/Destroy/OnEvent）
└── events/
    ├── {event_name}_event.yaml      # Event 声明
    └── {event_name}_event.py        # Event 实现
```

**manifest.yaml 配置：**
```yaml
plugins:
  triggers:
    - provider/{provider_name}.yaml
```

---

### 7.7 目录结构对比表

| 插件类型 | Provider 目录 | 核心功能目录 | manifest plugins 字段 |
|---------|--------------|-------------|---------------------|
| Tool | `provider/` | `tools/` | `tools` |
| Model | `provider/` | `models/{type}/` | `models` |
| Extension | `group/` | `endpoints/` | `endpoints` |
| Agent Strategy | `provider/` | `strategies/` | `agent_strategies` |
| Datasource | `provider/` | `datasources/` | `datasources` |
| Trigger | `provider/` | `events/` | `triggers` |

---

### 7.8 通用文件说明

| 文件 | 用途 |
|-----|------|
| `manifest.yaml` | 插件元数据、版本、权限声明 |
| `pyproject.toml` | Python 依赖 (uv 管理) |
| `README.md` | 插件说明文档 |
| `_assets/icon.svg` | 插件图标（SVG 格式） |
| `*.yaml` | 声明文件（参数、schema、i18n） |
| `*.py` | 实现文件（业务逻辑） |

---

## 附录

### A. 插件清单 (Manifest) 完整结构

```go
type PluginDeclaration struct {
    // 基本信息
    Version     string     // 版本号 (语义化版本)
    Type        string     // 类型: "plugin"
    Author      string     // 作者 (1-64 字符)
    Name        string     // 名称 (1-128 字符)
    Label       I18nObject // 多语言标签 (必需)
    Description I18nObject // 多语言描述 (必需)
    Icon        string     // 图标路径 (必需, 最长 128 字符)
    IconDark    string     // 深色主题图标 (可选)

    // 资源要求
    Resource PluginResourceRequirement

    // 插件组件声明
    Plugins PluginExtensions

    // 运行时元信息
    Meta PluginMeta

    // 分类标签
    Tags []PluginTag

    // 时间戳
    CreatedAt time.Time

    // 可选信息
    Privacy *string // 隐私政策
    Repo    *string // 代码仓库

    // 提供者声明 (根据类型选择)
    Verified      bool
    Endpoint      *EndpointProviderDeclaration
    Model         *ModelProviderDeclaration
    Tool          *ToolProviderDeclaration
    AgentStrategy *AgentStrategyProviderDeclaration
    Datasource    *DatasourceProviderDeclaration
    Trigger       *TriggerProviderDeclaration
}

// 资源要求
type PluginResourceRequirement struct {
    Memory     int64                        // 内存 (字节)
    Permission *PluginPermissionRequirement // 权限要求
}

// 权限要求
type PluginPermissionRequirement struct {
    Tool     *PluginPermissionToolRequirement     // 工具调用权限
    Model    *PluginPermissionModelRequirement    // 模型调用权限
    Node     *PluginPermissionNodeRequirement     // 节点调用权限
    Endpoint *PluginPermissionEndpointRequirement // 端点注册权限
    App      *PluginPermissionAppRequirement      // 应用调用权限
    Storage  *PluginPermissionStorageRequirement  // 存储权限
}

// 运行时元信息
type PluginMeta struct {
    Version            string   // 元信息版本
    Arch               []Arch   // 支持架构: amd64, arm64
    Runner             PluginRunner
    MinimumDifyVersion *string  // 最低 Dify 版本
}

type PluginRunner struct {
    Language   string // 语言: python
    Version    string // 版本: 3.11
    Entrypoint string // 入口点
}
```

### B. 多语言对象结构

```go
type I18nObject struct {
    EnUS   string `json:"en_US"`            // 英文 (必需)
    JaJp   string `json:"ja_JP,omitempty"`  // 日文
    ZhHans string `json:"zh_Hans,omitempty"` // 简体中文
    PtBr   string `json:"pt_BR,omitempty"`  // 葡萄牙语
}
```

### C. 支持的标签

```go
// 可用标签
search, image, videos, weather, finance, design, travel, social,
news, medical, productivity, education, business, entertainment,
utilities, agent, rag, other, trigger
```

### D. 配置类型

```go
const (
    CONFIG_TYPE_SECRET_INPUT   = "secret-input"   // 敏感输入
    CONFIG_TYPE_TEXT_INPUT     = "text-input"     // 文本输入
    CONFIG_TYPE_SELECT         = "select"         // 下拉选择
    CONFIG_TYPE_BOOLEAN        = "boolean"        // 布尔值
    CONFIG_TYPE_MODEL_SELECTOR = "model-selector" // 模型选择器
    CONFIG_TYPE_APP_SELECTOR   = "app-selector"   // 应用选择器
    CONFIG_TYPE_TOOLS_SELECTOR = "array[tools]"   // 工具选择器
    CONFIG_TYPE_ANY            = "any"            // 任意类型
)
```
