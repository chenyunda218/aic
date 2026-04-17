defmodule AIC.Chat do
  @moduledoc """
  統一的 Chat API 接口。

  提供跨 OpenAI 和 Anthropic 的一致接口，自動根據客戶端提供商
  調用相應的 API。

  ## 使用示例

      client = AIC.openai(api_key: "sk-...")

      {:ok, response} = AIC.Chat.completion(client, %{
        messages: [%{role: "user", content: "Hello!"}]
      })

      IO.puts(response.content)
  """

  alias AIC.Client
  alias AIC.Providers.OpenAI
  alias AIC.Providers.Anthropic

  @doc """
  創建聊天完成請求。

  根據客戶端的提供商自動選擇對應的 API。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數

  ## 返回

  返回統一格式的響應：

      {:ok, %{
        content: "生成的文本內容",
        model: "使用的模型",
        usage: %{prompt_tokens: 10, completion_tokens: 20}
      }}

  ## 示例

      # OpenAI
      client = AIC.openai(api_key: System.get_env("OPENAI_API_KEY"))

      {:ok, response} = AIC.Chat.completion(client, %{
        model: "gpt-4o",
        messages: [
          %{role: "system", content: "You are helpful."},
          %{role: "user", content: "Hello!"}
        ]
      })

      IO.puts(response.content)

      # Anthropic
      client = AIC.anthropic(api_key: System.get_env("ANTHROPIC_API_KEY"))

      {:ok, response} = AIC.Chat.completion(client, %{
        model: "claude-3-5-sonnet-20241022",
        messages: [%{role: "user", content: "Hello!"}]
      })

      IO.puts(response.content)
  """
  @spec completion(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def completion(%Client{provider: :openai} = client, params) do
    case OpenAI.chat_completion(client, params) do
      {:ok, response} -> {:ok, normalize_openai_response(response)}
      {:error, reason} -> {:error, reason}
    end
  end

  def completion(%Client{provider: :anthropic} = client, params) do
    case Anthropic.messages(client, params) do
      {:ok, response} -> {:ok, normalize_anthropic_response(response)}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  流式聊天完成請求。

  ## 參數

    - `client` - AIC 客戶端實例
    - `params` - 請求參數
    - `callback` - 處理每個內容塊的回調函數

  ## 示例

      AIC.Chat.stream_completion(client, %{messages: [%{role: "user", content: "Hi"}]}, fn text ->
        IO.write(text)
      end)
  """
  @spec stream_completion(Client.t(), map(), (String.t() -> any())) ::
          {:ok, term()} | {:error, term()}
  def stream_completion(%Client{provider: :openai} = client, params, callback) do
    OpenAI.stream_chat_completion(client, params, fn chunk ->
      content = get_in(chunk, ["choices", Access.at(0), "delta", "content"])
      if is_binary(content), do: callback.(content)
    end)
  end

  def stream_completion(%Client{provider: :anthropic} = client, params, callback) do
    Anthropic.stream_messages(client, params, fn chunk ->
      case chunk do
        %{"type" => "content_block_delta", "delta" => %{"text" => text}} ->
          callback.(text)

        _ ->
          :ok
      end
    end)
  end

  # 私有函數：標準化響應格式

  defp normalize_openai_response(response) do
    choice = List.first(response["choices"] || [])
    message = choice["message"] || %{}

    %{
      content: message["content"],
      role: message["role"],
      model: response["model"],
      usage: normalize_usage(response["usage"]),
      finish_reason: choice["finish_reason"],
      raw: response
    }
  end

  defp normalize_anthropic_response(response) do
    content_blocks = response["content"] || []

    text_content =
      content_blocks
      |> Enum.filter(&(&1["type"] == "text"))
      |> Enum.map_join(& &1["text"])

    %{
      content: text_content,
      role: response["role"],
      model: response["model"],
      usage: normalize_usage(response["usage"]),
      stop_reason: response["stop_reason"],
      raw: response
    }
  end

  defp normalize_usage(nil), do: nil

  defp normalize_usage(usage) do
    %{
      prompt_tokens: usage["prompt_tokens"] || usage["input_tokens"],
      completion_tokens: usage["completion_tokens"] || usage["output_tokens"],
      total_tokens: usage["total_tokens"]
    }
  end
end
