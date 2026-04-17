defmodule AIC.Providers.Anthropic do
  @moduledoc """
  Anthropic API 的具體實現。

  提供對 Anthropic Messages API 的類型化訪問。
  """

  alias AIC.Client

  @default_model "claude-3-5-sonnet-20241022"
  @default_max_tokens 1024

  @doc """
  創建消息請求。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數

  ## 參數選項

    - `:model` - 模型 ID（默認 "claude-3-5-sonnet-20241022"）
    - `:messages` - 消息列表（必填）
    - `:max_tokens` - 最大生成 token 數（必填，默認 1024）
    - `:temperature` - 採樣溫度（0-1）
    - `:system` - 系統提示詞
    - `:stream` - 是否啟用流式輸出

  ## 示例

      {:ok, response} = AIC.Providers.Anthropic.messages(client, %{
        model: "claude-3-5-sonnet-20241022",
        max_tokens: 1024,
        messages: [
          %{role: "user", content: "Hello, Claude!"}
        ]
      })
  """
  @spec messages(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def messages(%Client{} = client, params) do
    params =
      params
      |> Map.put_new(:model, @default_model)
      |> Map.put_new(:max_tokens, @default_max_tokens)
      |> normalize_messages()

    Client.post(client, "/messages", params)
  end

  @doc """
  流式消息請求。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數
    - `callback` - 處理每個數據塊的回調函數

  ## 示例

      AIC.Providers.Anthropic.stream_messages(client, %{
        max_tokens: 1024,
        messages: [%{role: "user", content: "Tell me a story"}]
      }, fn chunk ->
        case chunk do
          %{"type" => "content_block_delta", "delta" => %{"text" => text}} ->
            IO.write(text)
          _ ->
            :ok
        end
      end)
  """
  @spec stream_messages(Client.t(), map(), (map() -> any())) ::
          {:ok, term()} | {:error, term()}
  def stream_messages(%Client{} = client, params, callback) do
    params =
      params
      |> Map.put_new(:model, @default_model)
      |> Map.put_new(:max_tokens, @default_max_tokens)
      |> normalize_messages()

    Client.stream_post(client, "/messages", params, callback)
  end

  # 私有函數

  defp normalize_messages(params) do
    case Map.get(params, :messages) do
      nil ->
        params

      messages when is_list(messages) ->
        normalized =
          Enum.map(messages, fn
            %{role: role, content: content} ->
              %{"role" => to_string(role), "content" => content}

            %{} = msg ->
              msg
              |> Map.new(fn {k, v} -> {to_string(k), v} end)
          end)

        Map.put(params, :messages, normalized)

      _ ->
        params
    end
  end
end
