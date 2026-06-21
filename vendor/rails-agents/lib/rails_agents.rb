# frozen_string_literal: true

require "zeitwerk"
require "json"

loader = Zeitwerk::Loader.for_gem
loader.ignore("#{__dir__}/generators")
loader.inflector.inflect(
  "openai" => "OpenAI",
  "openai_compatible" => "OpenAICompatible",
  "anthropic" => "Anthropic",
  "open_router" => "OpenRouter"
)
loader.setup

require_relative "rails_agents/message"
require_relative "rails_agents/result"
require_relative "rails_agents/error"
require_relative "rails_agents/skill_declaration"
require_relative "rails_agents/generated_file"
require_relative "rails_agents/providers/openai_compatible"

module RailsAgents
  class << self
    attr_writer :config

    def config
      @config ||= Configuration.new
    end

    def configure
      yield config
    end

    def tools(*classes)
      ToolSet.use(*classes)
    end
  end
end

require_relative "rails_agents/version"
