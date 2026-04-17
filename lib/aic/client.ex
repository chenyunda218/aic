defmodule AIC.Client do
  @moduledoc """
  AIC HTTP Client 模塊，基於 Tesla 構建。

  支持 OpenAI 和 Anthropic API，提供統一的 HTTP 請求接口。

  ## 使用示例

      # 創建 OpenAI 客戶端
      client = AIC.Client.new(:openai, api_key: "sk-...")

      # 創建 Anthropic 客戶端
      client = AIC.Client.new(:anthropic, api_key: "sk-ant-...")

      # 發送 POST 請求
      {:ok, response} = AIC.Client.post(client, "/chat/completions", %{
        model: "gpt-4o",
        messages: [%{role: "user", content: "Hello"}]
      })
  """

  @typedoc "支持的 AI 提供商"
  @type provider :: :openai | :anthropic

  @typedoc "客戶端配置選項"
  @type opts :: [
          api_key: String.t(),
          base_url: String.t(),
          timeout: non_neg_integer(),
          recv_timeout: non_neg_integer()
        ]

  @typedoc "客戶端結構體"
  @type t :: %__MODULE__{
          provider: provider(),
          api_key: String.t(),
          base_url: String.t(),
          http_client: module()
        }

  defstruct [
    :provider,
    :api_key,
    :base_url,
    :http_client
  ]

  # 默認基礎 URL
  @openai_base_url "https://api.openai.com/v1"
  @anthropic_base_url "https://api.anthropic.com/v1"

  # 默認超時設置（毫秒）
  @default_timeout 60_000
  @default_recv_timeout 60_000

  @doc """
  創建一個新的 API 客戶端。

  ## 參數

    - `provider` - 提供商類型 (`:openai` 或 `:anthropic`)
    - `opts` - 配置選項

  ## 選項

    - `:api_key` - API 密鑰（必填）
    - `:base_url` - 自定義 API 基礎 URL
    - `:timeout` - 連接超時時間（默認 60000ms）
    - `:recv_timeout` - 接收超時時間（默認 60000ms）

  ## 示例

      iex> AIC.Client.new(:openai, api_key: "sk-test")
      %AIC.Client{provider: :openai, api_key: "sk-test", ...}
  """
  @spec new(provider(), opts()) :: t()
  def new(provider, opts \\ []) when provider in [:openai, :anthropic] do
    api_key = Keyword.fetch!(opts, :api_key)
    base_url = Keyword.get(opts, :base_url, default_base_url(provider))
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    recv_timeout = Keyword.get(opts, :recv_timeout, @default_recv_timeout)

    # 創建 Tesla 客戶端
    http_client = build_http_client(base_url, timeout, recv_timeout)

    %__MODULE__{
      provider: provider,
      api_key: api_key,
      base_url: base_url,
      http_client: http_client
    }
  end

  @doc """
  發送 GET 請求。

  ## 示例

      {:ok, response} = AIC.Client.get(client, "/models")
  """
  @spec get(t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(%__MODULE__{} = client, path) do
    request(client, :get, path, "")
  end

  @doc """
  發送 POST 請求。

  ## 示例

      {:ok, response} = AIC.Client.post(client, "/chat/completions", %{
        model: "gpt-4o",
        messages: [%{role: "user", content: "Hello"}]
      })
  """
  @spec post(t(), String.t(), map()) :: {:ok, map()} | {:error, term()}
  def post(%__MODULE__{} = client, path, body) do
    request(client, :post, path, body)
  end

  @doc """
  發送 DELETE 請求。

  ## 示例

      {:ok, response} = AIC.Client.delete(client, "/models/gpt-3.5-turbo")
  """
  @spec delete(t(), String.t()) :: {:ok, map()} | {:error, term()}
  def delete(%__MODULE__{} = client, path) do
    request(client, :delete, path, "")
  end

  @doc """
  發送流式 POST 請求，支持 Server-Sent Events (SSE)。

  ## 參數

    - `client` - 客戶端實例
    - `path` - API 路徑
    - `body` - 請求體（需要包含 `stream: true`）
    - `callback` - 處理每個數據塊的回調函數

  ## 示例

      AIC.Client.stream_post(client, "/chat/completions", %{
        model: "gpt-4o",
        messages: [%{role: "user", content: "Hello"}],
        stream: true
      }, fn chunk ->
        IO.write(chunk["choices"][0]["delta"]["content"])
      end)
  """
  @spec stream_post(t(), String.t(), map(), (map() -> any())) ::
          {:ok, term()} | {:error, term()}
  def stream_post(%__MODULE__{} = client, path, body, callback)
      when is_function(callback, 1) do
    # 確保啟用流式
    body = Map.put(body, :stream, true)

    # 構建請求
    url = client.base_url <> path
    headers = build_headers(client)
    json_body = Jason.encode!(body)

    # 使用 Finch 或 Mint 進行流式請求
    case stream_request(url, headers, json_body, callback) do
      {:ok, result} -> {:ok, result}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc """
  獲取客戶端的提供商類型。
  """
  @spec provider(t()) :: provider()
  def provider(%__MODULE__{provider: provider}), do: provider

  @doc """
  獲取客戶端的基礎 URL。
  """
  @spec base_url(t()) :: String.t()
  def base_url(%__MODULE__{base_url: url}), do: url

  # 私有函數

  defp default_base_url(:openai), do: @openai_base_url
  defp default_base_url(:anthropic), do: @anthropic_base_url

  defp build_http_client(base_url, timeout, recv_timeout) do
    middleware = [
      {Tesla.Middleware.BaseUrl, base_url},
      Tesla.Middleware.JSON,
      {Tesla.Middleware.Timeout, timeout: timeout},
      {Tesla.Middleware.Opts, [adapter: [recv_timeout: recv_timeout]]}
    ]

    adapter = {Tesla.Adapter.Mint, []}

    Tesla.client(middleware, adapter)
  end

  defp request(%__MODULE__{} = client, method, path, body) do
    url = client.base_url <> path
    headers = build_headers(client)

    body =
      case body do
        "" -> ""
        _ when is_map(body) -> Jason.encode!(body)
        _ -> body
      end

    # 構建 Tesla 請求選項
    opts = [
      headers: headers,
      body: body
    ]

    case apply(Tesla, method, [client.http_client, url, opts]) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status, body: body}} ->
        {:error, %{status: status, body: body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp build_headers(%__MODULE__{provider: :openai, api_key: api_key}) do
    [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]
  end

  defp build_headers(%__MODULE__{provider: :anthropic, api_key: api_key}) do
    [
      {"x-api-key", api_key},
      {"anthropic-version", "2023-06-01"},
      {"Content-Type", "application/json"}
    ]
  end

  # 流式請求實現
  defp stream_request(url, headers, body, callback) do
    headers = headers ++ [{"Accept", "text/event-stream"}]

    case Mint.HTTP.connect(:https, host_from_url(url), 443) do
      {:ok, conn} ->
        {:ok, conn, request_ref} =
          Mint.HTTP.request(conn, "POST", path_from_url(url), headers, body)

        result = stream_response(conn, request_ref, callback, "")
        Mint.HTTP.close(conn)
        result

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp stream_response(conn, request_ref, callback, buffer) do
    receive do
      message ->
        case Mint.HTTP.stream(conn, message) do
          :unknown ->
            stream_response(conn, request_ref, callback, buffer)

          {:ok, conn, responses} ->
            {conn, buffer, done} =
              Enum.reduce(responses, {conn, buffer, false}, fn
                {:status, ^request_ref, status}, {conn, buffer, _} ->
                  if status != 200 do
                    {conn, buffer, :error}
                  else
                    {conn, buffer, false}
                  end

                {:headers, ^request_ref, _headers}, acc ->
                  acc

                {:data, ^request_ref, data}, {conn, buffer, status} ->
                  new_buffer = buffer <> data
                  {remaining, done} = process_sse_data(new_buffer, callback)
                  {conn, remaining, done || status}

                {:done, ^request_ref}, {conn, buffer, _} ->
                  {conn, buffer, true}
              end)

            if done == true do
              {:ok, :stream_completed}
            else
              if done == :error do
                {:error, :request_failed}
              else
                stream_response(conn, request_ref, callback, buffer)
              end
            end

          {:error, conn, reason, _responses} ->
            Mint.HTTP.close(conn)
            {:error, reason}
        end
    after
      60_000 ->
        {:error, :timeout}
    end
  end

  # 處理 SSE 數據
  defp process_sse_data(data, callback) do
    lines = String.split(data, "\n\n")
    {remaining, events} = List.pop_at(lines, -1)

    events
    |> Enum.each(fn event ->
      event
      |> String.split("\n")
      |> Enum.each(fn line ->
        case String.trim(line) do
          "data: " <> json_data ->
            case Jason.decode(json_data) do
              {:ok, parsed} -> callback.(parsed)
              {:error, _} -> :ok
            end

          _ ->
            :ok
        end
      end)
    end)

    {remaining || "", false}
  end

  defp host_from_url("https://" <> rest) do
    rest
    |> String.split("/")
    |> List.first()
  end

  defp host_from_url(url), do: url

  defp path_from_url("https://" <> rest) do
    case String.split(rest, "/", parts: 2) do
      [_host] -> "/"
      [_host, path] -> "/" <> path
    end
  end

  defp path_from_url(_), do: "/"
end
