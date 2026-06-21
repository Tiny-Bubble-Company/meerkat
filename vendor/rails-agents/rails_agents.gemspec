# frozen_string_literal: true

require_relative "lib/rails_agents/version"

Gem::Specification.new do |spec|
  spec.name = "rails_agents"
  spec.version = RailsAgents::VERSION
  spec.authors = ["Rails Agents contributors"]
  spec.email = ["hello@railsagents.dev"]
  spec.summary = "Dead-simple AI agents for Rails"
  spec.description = "Build Answer, Workflow, Decision, Monitor, Data, and Communication agents with one DSL. OpenAI and Anthropic included."
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2"

  spec.files = Dir.chdir(__dir__) do
    Dir["lib/**/*", "README.md", "MIT-LICENSE"]
  end

  spec.add_dependency "faraday", ">= 2.9", "< 3"
  spec.add_dependency "rails", ">= 7.1", "< 9"
  spec.add_dependency "zeitwerk", ">= 2.6", "< 3"
end
