defmodule AIC.Providers.OpenAI do
  @moduledoc """
  OpenAI API 的具體實現。

  提供對 OpenAI API 端點的類型化訪問。
  """

  alias AIC.Client

  @default_model "gpt-4o"

  @doc """
  創建聊天完成請求。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數

  ## 參數選項

    - `:model` - 模型 ID（默認 "gpt-4o"）
    - `:messages` - 消息列表（必填）
    - `:temperature` - 採樣溫度（0-2）
    - `:max_tokens` - 最大生成 token 數
    - `:stream` - 是否啟用流式輸出

  ## 示例

      {:ok, response} = AIC.Providers.OpenAI.chat_completion(client, %{
        model: "gpt-4o",
        messages: [
          %{role: "system", content: "You are a helpful assistant."},
          %{role: "user", content: "Hello!"}
        ]
      })
  """
  @spec chat_completion(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def chat_completion(%Client{} = client, params) do
    params =
      params
      |> Map.put_new(:model, @default_model)
      |> normalize_messages()

    Client.post(client, "/chat/completions", params)
  end

  @doc """
  流式聊天完成請求。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數
    - `callback` - 處理每個數據塊的回調函數

  ## 示例

      AIC.Providers.OpenAI.stream_chat_completion(client, %{
        model: "gpt-4o",
        messages: [%{role: "user", content: "Tell me a story"}]
      }, fn chunk ->
        content = get_in(chunk, ["choices", Access.at(0), "delta", "content"])
        if content, do: IO.write(content)
      end)
  """
  @spec stream_chat_completion(Client.t(), map(), (map() -> any())) ::
          {:ok, term()} | {:error, term()}
  def stream_chat_completion(%Client{} = client, params, callback) do
    params =
      params
      |> Map.put_new(:model, @default_model)
      |> normalize_messages()

    Client.stream_post(client, "/chat/completions", params, callback)
  end

  @doc """
  獲取可用模型列表。

  ## 示例

      {:ok, %{"data" => models}} = AIC.Providers.OpenAI.list_models(client)
  """
  @spec list_models(Client.t()) :: {:ok, map()} | {:error, term()}
  def list_models(%Client{} = client) do
    Client.get(client, "/models")
  end

  @doc """
  創建嵌入向量。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數

  ## 示例

      {:ok, response} = AIC.Providers.OpenAI.create_embedding(client, %{
        model: "text-embedding-3-small",
        input: "Hello world"
      })
  """
  @spec create_embedding(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def create_embedding(%Client{} = client, params) do
    Client.post(client, "/embeddings", params)
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
    end
  end
end
