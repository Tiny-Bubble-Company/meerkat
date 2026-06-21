# frozen_string_literal: true

module RailsAgents
  module Providers
    class Base
    def chat(messages:, tools: [], client_tools: tools, skills: nil, model:, json: false, &block)
      raise NotImplementedError
    end
    end

    def self.build(name, api_key: nil)
      case name.to_sym
      when :openai then OpenAI.new(api_key: api_key)
      when :anthropic then Anthropic.new(api_key: api_key)
      when :openrouter then OpenRouter.new(api_key: api_key)
      when :grok then Grok.new(api_key: api_key)
      else raise ConfigurationError, "Unknown provider: #{name}. Use: #{Configuration::PROVIDERS.join(', ')}"
      end
    end
  end
end
