# frozen_string_literal: true

module Agents
  class RunForCustomer
    class Error < StandardError; end

    def self.call(customer:, input:, **context)
      new(customer:, input:, context:).call
    end

    def initialize(customer:, input:, context: {})
      @customer = customer
      @input = input
      @context = context
    end

    def call
      provider_name, api_key, model = resolve_credentials

      provider = RailsAgents::Providers.build(provider_name, api_key: api_key)

      RailsAgents::Runner.new(
        TaskExecutor,
        input: @input,
        context: @context,
        parse_json: true,
        provider: provider,
        model: model
      ).call
    end

    private

    def resolve_credentials
      if @customer.llm_configured?
        return [
          @customer.llm_provider.to_sym,
          @customer.llm_api_key,
          @customer.resolved_llm_model
        ]
      end

      if platform_llm_available?
        return [
          platform_provider,
          platform_api_key,
          platform_model
        ]
      end

      raise Error, "Connect an LLM provider before running tasks"
    end

    def platform_llm_available?
      Rails.env.development? && platform_api_key.present?
    end

    def platform_provider
      RailsAgents.config.default_provider
    end

    def platform_api_key
      RailsAgents.config.api_key_for(platform_provider)
    end

    def platform_model
      TaskExecutor.model_name || Customers::SaveLlmCredential::DEFAULT_MODELS.fetch(platform_provider.to_s)
    end
  end
end
