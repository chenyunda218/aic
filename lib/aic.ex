defmodule AIC do
  @moduledoc """
  AIC (AI API Client) - 統一的 AI API 客戶端。

  支持 OpenAI 和 Anthropic API，提供簡潔、一致的接口。

  ## 快速開始

      # 創建 OpenAI 客戶端
      client = AIC.new(:openai, api_key: "your-api-key")

      # 創建 Anthropic 客戶端
      client = AIC.new(:anthropic, api_key: "your-api-key")

  ## 使用 Client 發送請求

      # GET 請求
      {:ok, models} = AIC.Client.get(client, "/models")

      # POST 請求
      {:ok, response} = AIC.Client.post(client, "/chat/completions", %{
        model: "gpt-4o",
        messages: [%{role: "user", content: "Hello!"}]
      })

  ## 流式請求

      AIC.Client.stream_post(client, "/chat/completions", %{
        model: "gpt-4o",
        messages: [%{role: "user", content: "Tell me a story"}],
        stream: true
      }, fn chunk ->
        IO.write(chunk["choices"][0]["delta"]["content"])
      end)
  """

  alias AIC.Client

  @doc """
  創建一個新的 AI API 客戶端。

  ## 參數

    - `provider` - 提供商類型 (`:openai` 或 `:anthropic`)
    - `opts` - 配置選項

  ## 選項

    - `:api_key` - API 密鑰（必填）
    - `:base_url` - 自定義 API 基礎 URL
    - `:timeout` - 連接超時時間（毫秒）
    - `:recv_timeout` - 接收超時時間（毫秒）

  ## 示例

      # OpenAI
      client = AIC.new(:openai, api_key: System.get_env("OPENAI_API_KEY"))

      # Anthropic
      client = AIC.new(:anthropic, api_key: System.get_env("ANTHROPIC_API_KEY"))

      # 自定義配置
      client = AIC.new(:openai,
        api_key: "sk-...",
        base_url: "https://custom-proxy.com/v1",
        timeout: 30_000
      )
  """
  @spec new(Client.provider(), Client.opts()) :: Client.t()
  defdelegate new(provider, opts \\ []), to: Client

  @doc """
  創建一個 OpenAI 客戶端（便捷函數）。

  ## 示例

      client = AIC.openai(api_key: "sk-...")
  """
  @spec openai(keyword()) :: Client.t()
  def openai(opts) do
    Client.new(:openai, opts)
  end

  @doc """
  創建一個 Anthropic 客戶端（便捷函數）。

  ## 示例

      client = AIC.anthropic(api_key: "sk-ant-...")
  """
  @spec anthropic(keyword()) :: Client.t()
  def anthropic(opts) do
    Client.new(:anthropic, opts)
  end

  @doc """
  獲取客戶端的提供商類型。
  """
  @spec provider(Client.t()) :: Client.provider()
  defdelegate provider(client), to: Client

  @doc """
  獲取客戶端的基礎 URL。
  """
  @spec base_url(Client.t()) :: String.t()
  defdelegate base_url(client), to: Client
end
