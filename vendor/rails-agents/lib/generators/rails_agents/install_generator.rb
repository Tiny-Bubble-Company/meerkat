# frozen_string_literal: true

require "rails/generators"

module RailsAgents
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)
      desc "Add Rails Agents config and agent directories"

      def create_initializer
        template "initializer.rb", "config/initializers/rails_agents.rb"
      end

      def create_directories
        empty_directory "app/agents"
        empty_directory "app/agents/tools"
        create_file "app/agents/.keep"
        create_file "app/agents/tools/.keep"
      end

      def finish
        say "\n✓ Rails Agents installed.", :green
        say "  1. Set API keys in config/initializers/rails_agents.rb"
        say "  2. Create agents in app/agents/"
      end
    end
  end
end
