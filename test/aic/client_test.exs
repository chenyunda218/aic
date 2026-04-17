defmodule AIC.ClientTest do
  use ExUnit.Case
  alias AIC.Client

  describe "new/2" do
    test "creates OpenAI client" do
      client = Client.new(:openai, api_key: "sk-test")

      assert client.provider == :openai
      assert client.api_key == "sk-test"
      assert client.base_url == "https://api.openai.com/v1"
      assert client.http_client != nil
    end

    test "creates Anthropic client" do
      client = Client.new(:anthropic, api_key: "sk-ant-test")

      assert client.provider == :anthropic
      assert client.api_key == "sk-ant-test"
      assert client.base_url == "https://api.anthropic.com/v1"
      assert client.http_client != nil
    end

    test "accepts custom base_url" do
      client = Client.new(:openai,
        api_key: "sk-test",
        base_url: "https://custom.example.com/v1"
      )

      assert client.base_url == "https://custom.example.com/v1"
    end

    test "raises when api_key is missing" do
      assert_raise KeyError, fn ->
        Client.new(:openai, [])
      end
    end
  end

  describe "provider/1" do
    test "returns provider" do
      client = Client.new(:openai, api_key: "sk-test")
      assert Client.provider(client) == :openai
    end
  end

  describe "base_url/1" do
    test "returns base_url" do
      client = Client.new(:anthropic, api_key: "sk-ant-test")
      assert Client.base_url(client) == "https://api.anthropic.com/v1"
    end
  end
end
