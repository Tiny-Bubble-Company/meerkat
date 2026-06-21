# frozen_string_literal: true

module RailsAgents
  module Providers
    class Grok < OpenAICompatible
      def initialize(api_key: RailsAgents.config.grok_api_key, base_url: "https://api.x.ai/v1")
        super(
          api_key: api_key,
          base_url: base_url,
          missing_key_message: "Set grok_api_key (or XAI_API_KEY) in config/initializers/rails_agents.rb"
        )
      end
    end
  end
end
