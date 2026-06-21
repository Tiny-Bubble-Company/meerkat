# frozen_string_literal: true

module Customers
  class SaveLlmCredential
    class Error < StandardError; end

    PROVIDERS = %w[anthropic openai openrouter grok].freeze

    DEFAULT_MODELS = {
      "anthropic"   => "claude-sonnet-4-6",
      "openai"      => "gpt-4o-mini",
      "openrouter"  => "meta-llama/llama-3.3-70b-instruct:free",
      "grok"        => "grok-3-mini"
    }.freeze

    KEY_PLACEHOLDERS = {
      "anthropic"  => "sk-ant-...",
      "openai"     => "sk-...",
      "openrouter" => "sk-or-...",
      "grok"       => "xai-..."
    }.freeze

    def self.call(customer:, provider:, api_key:, model: nil)
      new(customer:, provider:, api_key:, model:).call
    end

    def initialize(customer:, provider:, api_key:, model: nil)
      @customer = customer
      @provider = provider.to_s.strip.downcase
      @api_key = api_key.to_s.strip
      @model = model.to_s.strip.presence
    end

    def call
      validate!

      attributes = {
        llm_provider: @provider,
        llm_model: @model
      }
      attributes[:llm_api_key] = @api_key if @api_key.present?

      @customer.update!(attributes)

      @customer
    end

    private

    def validate!
      raise Error, "Provider is required" if @provider.blank?
      raise Error, "Provider must be one of: #{PROVIDERS.join(', ')}" unless PROVIDERS.include?(@provider)
      return if @api_key.present?
      return if @customer.llm_configured? && @provider == @customer.llm_provider

      raise Error, "API key is required"
    end
  end
end
