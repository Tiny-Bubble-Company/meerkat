# frozen_string_literal: true

module RailsAgents
  module Providers
    class OpenRouter < OpenAICompatible
      def initialize(api_key: RailsAgents.config.openrouter_api_key, base_url: "https://openrouter.ai/api/v1")
        super(
          api_key: api_key,
          base_url: base_url,
          extra_headers: {
            "HTTP-Referer" => (defined?(Rails) ? "https://#{Rails.application.class.module_parent_name.downcase}.app" : "https://railsagents.dev"),
            "X-Title" => (defined?(Rails) ? Rails.application.class.module_parent_name : "Rails Agents")
          },
          missing_key_message: "Set openrouter_api_key in config/initializers/rails_agents.rb"
        )
      end
    end
  end
end
