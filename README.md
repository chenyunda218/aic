# AIC - AI API Client

[![Elixir](https://img.shields.io/badge/Elixir-~>1.19-purple.svg)](https://elixir-lang.org/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

一個統一的 AI API 客戶端，支持 OpenAI 和 Anthropic API。使用 Elixir 編寫，提供簡潔、一致的接口來訪問多種 AI 服務。

## 功能特性

- 🚀 **雙 API 支持** - 同時支持 OpenAI 和 Anthropic API
- 🔧 **統一接口** - 一致的 API 設計，輕鬆切換不同提供商
- ⚡ **異步支持** - 基於 Elixir 的並發模型，高效處理請求
- 🔄 **流式響應** - 支持 Server-Sent Events (SSE) 流式輸出
- 🛡️ **類型安全** - 完整的類型規範和文檔
- 🔌 **可擴展** - 易於擴展支持更多 AI 提供商

## 安裝

將 `aic` 添加到 `mix.exs` 的依賴列表中：

```elixir
def deps do
  [
    {:aic, "~> 0.1.0"}
  ]
end
```

然後運行：

```bash
mix deps.get
```

## 快速開始

### 配置 API 密鑰

在 `config/runtime.exs` 或環境變量中設置 API 密鑰：

```elixir
# config/runtime.exs
config :aic, :openai,
  api_key: System.get_env("OPENAI_API_KEY"),
  base_url: "https://api.openai.com/v1"

config :aic, :anthropic,
  api_key: System.get_env("ANTHROPIC_API_KEY"),
  base_url: "https://api.anthropic.com/v1"
```

### 基本使用

#### OpenAI

```elixir
# 創建 OpenAI 客戶端
client = AIC.new(
  provider: :openai,
  api_key: "your-openai-api-key"
)

# 發送聊天請求
{:ok, response} = AIC.Chat.completion(client, %{
  model: "gpt-4o",
  messages: [
    %{role: "system", content: "You are a helpful assistant."},
    %{role: "user", content: "Hello, how are you?"}
  ]
})

IO.inspect(response.choices[0].message.content)
```

#### Anthropic

```elixir
# 創建 Anthropic 客戶端
client = AIC.new(
  provider: :anthropic,
  api_key: "your-anthropic-api-key"
)

# 發送消息請求
{:ok, response} = AIC.Messages.create(client, %{
  model: "claude-3-5-sonnet-20241022",
  max_tokens: 1024,
  messages: [
    %{role: "user", content: "Hello, Claude!"}
  ]
})

IO.inspect(response.content[0].text)
```

### 統一接口

使用統一接口，輕鬆在不同提供商之間切換：

```elixir
# 定義配置
configs = [
  openai: [
    provider: :openai,
    api_key: System.get_env("OPENAI_API_KEY"),
    model: "gpt-4o"
  ],
  anthropic: [
    provider: :anthropic,
    api_key: System.get_env("ANTHROPIC_API_KEY"),
    model: "claude-3-5-sonnet-20241022"
  ]
]

# 使用相同的代碼調用不同提供商
for {name, config} <- configs do
  client = AIC.new(config)
  
  {:ok, response} = AIC.complete(client, %{
    messages: [%{role: "user", content: "Say hello!"}]
  })
  
  IO.puts("#{name}: #{response.content}")
end
```

## 進階功能

### 流式響應

```elixir
client = AIC.new(provider: :openai, api_key: api_key)

AIC.Chat.completion(client, %{
  model: "gpt-4o",
  messages: [%{role: "user", content: "Tell me a story"}],
  stream: true
}, fn chunk ->
  IO.write(chunk.choices[0].delta.content)
end)
```

### 自定義 HTTP 配置

```elixir
client = AIC.new(
  provider: :openai,
  api_key: api_key,
  http_opts: [
    timeout: 60_000,
    recv_timeout: 60_000
  ]
)
```

## 支持的 API

### OpenAI

- [x] Chat Completions
- [x] Embeddings
- [x] Models
- [x] Streaming
- [ ] Assistants API
- [ ] Files
- [ ] Fine-tuning

### Anthropic

- [x] Messages
- [x] Streaming
- [ ] Embeddings
- [ ] Batch Processing

## 配置選項

| 選項 | 類型 | 描述 | 默認值 |
|------|------|------|--------|
| `:provider` | `atom` | AI 提供商 (`:openai` 或 `:anthropic`) | 必填 |
| `:api_key` | `string` | API 密鑰 | 必填 |
| `:base_url` | `string` | 自定義 API 基礎 URL | 提供商默認值 |
| `:model` | `string` | 默認模型 | 提供商默認值 |
| `:http_opts` | `keyword` | HTTP 客戶端選項 | `[]` |

## 開發

### 運行測試

```bash
mix test
```

### 運行靜態分析

```bash
mix dialyzer
```

### 代碼格式化

```bash
mix format
```

## 項目結構

```
aic/
├── lib/
│   ├── aic.ex              # 主入口模塊
│   └── aic/
│       ├── client.ex       # HTTP 客戶端
│       ├── providers/      # 提供商實現
│       │   ├── openai.ex
│       │   └── anthropic.ex
│       └── utils.ex        # 工具函數
├── test/
└── mix.exs
```

## 依賴

- [Tesla](https://github.com/elixir-tesla/tesla) - HTTP 客戶端
- [Jason](https://github.com/michalmuskala/jason) - JSON 編解碼器
- [Mint](https://github.com/elixir-mint/mint) - HTTP/2 客戶端

## 貢獻

歡迎提交 Issue 和 Pull Request！請確保：

1. 代碼通過 `mix format` 格式化
2. 所有測試通過 `mix test`
3. 添加相應的測試用例

## 許可證

本項目採用 MIT 許可證 - 詳見 [LICENSE](LICENSE) 文件。

## 相關資源

- [OpenAI API 文檔](https://platform.openai.com/docs)
- [Anthropic API 文檔](https://docs.anthropic.com/)
- [Elixir 官方網站](https://elixir-lang.org/)
- [Phoenix 框架](https://www.phoenixframework.org/)

---

<p align="center">Built with ❤️ using Elixir</p>
