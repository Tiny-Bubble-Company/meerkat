# frozen_string_literal: true

module Customers
  class ValidateLlmCredential
    class Error < SaveLlmCredential::Error; end

    def self.call(provider:, api_key:, model: nil)
      new(provider:, api_key:, model:).call
    end

    def initialize(provider:, api_key:, model: nil)
      @provider = provider.to_s.strip.downcase
      @api_key = api_key.to_s.strip
      @model = model.to_s.strip.presence
    end

    def call
      raise Error, "API key is required" if @api_key.blank?

      provider = RailsAgents::Providers.build(@provider.to_sym, api_key: @api_key)
      resolved_model = @model || SaveLlmCredential::DEFAULT_MODELS.fetch(@provider)

      response = provider.chat(
        messages: [ RailsAgents::Message.user("Reply with exactly: ok") ],
        client_tools: [],
        model: resolved_model
      )

      return if response.content.to_s.strip.present?

      raise Error, "Provider returned an empty response. Check your model name."
    rescue RailsAgents::ProviderError => e
      raise Error, friendly_message(e.message)
    end

    private

    def friendly_message(raw)
      message = raw.to_s.strip
      return "Invalid API key for #{@provider}. Check the key and try again." if message.match?(/auth|unauthorized|invalid.*key/i)
      return "Model not available for #{@provider}. Try the default model or pick another." if message.match?(/model|not found|does not exist/i)

      "Could not verify #{@provider} credentials: #{message}"
    end
  end
end
