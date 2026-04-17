defmodule AICTest do
  use ExUnit.Case

  describe "new/2" do
    test "creates OpenAI client" do
      client = AIC.new(:openai, api_key: "sk-test")
      assert AIC.provider(client) == :openai
    end

    test "creates Anthropic client" do
      client = AIC.new(:anthropic, api_key: "sk-ant-test")
      assert AIC.provider(client) == :anthropic
    end
  end

  describe "openai/1" do
    test "creates OpenAI client" do
      client = AIC.openai(api_key: "sk-test")
      assert AIC.provider(client) == :openai
      assert AIC.base_url(client) == "https://api.openai.com/v1"
    end
  end

  describe "anthropic/1" do
    test "creates Anthropic client" do
      client = AIC.anthropic(api_key: "sk-ant-test")
      assert AIC.provider(client) == :anthropic
      assert AIC.base_url(client) == "https://api.anthropic.com/v1"
    end
  end
end
