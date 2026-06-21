# frozen_string_literal: true

require "rails_agents"

module RailsAgents
  class Railtie < Rails::Railtie
    generators do
      require "generators/rails_agents/install_generator"
    end

    initializer "rails_agents.autoload", before: :set_autoload_paths do |app|
      agents_path = app.root.join("app/agents")
      next unless agents_path.exist?

      app.autoloaders.main.push_dir(agents_path.to_s)

      tools_path = agents_path.join("tools")
      app.autoloaders.main.collapse(tools_path.to_s) if tools_path.exist?
    end

    rake_tasks do
      load "rails_agents/tasks.rb" if File.exist?(File.expand_path("tasks.rb", __dir__))
    end
  end
end
