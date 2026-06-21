# frozen_string_literal: true

module RailsAgents
  module Providers
    class OpenAI < OpenAICompatible
      def initialize(api_key: RailsAgents.config.openai_api_key, base_url: "https://api.openai.com/v1")
        super(
          api_key: api_key,
          base_url: base_url,
          missing_key_message: "Set openai_api_key in config/initializers/rails_agents.rb"
        )
      end
    end
  end
end
