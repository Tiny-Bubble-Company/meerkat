# frozen_string_literal: true

require "fileutils"
require "pathname"

module RailsAgents
  class Configuration
    PROVIDERS = %i[openai anthropic openrouter grok].freeze

    attr_accessor :openai_api_key, :anthropic_api_key, :openrouter_api_key, :grok_api_key,
      :default_provider, :anthropic_auto_download_files, :anthropic_files_directory

    def initialize
      @openai_api_key = ENV["OPENAI_API_KEY"]
      @anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
      @openrouter_api_key = ENV["OPENROUTER_API_KEY"]
      @grok_api_key = ENV["XAI_API_KEY"] || ENV["GROK_API_KEY"]
      @default_provider = :openai
      @anthropic_auto_download_files = true
      @anthropic_files_directory = nil
    end

    def api_key_for(provider)
      public_send(:"#{provider}_api_key")
    end

    def anthropic_files_directory!
      return Pathname.new(@anthropic_files_directory) if @anthropic_files_directory.to_s != ""

      return Rails.root.join("tmp/rails_agents/files") if defined?(Rails)

      Pathname.new(Dir.mktmpdir("rails_agents_files_"))
    end
  end
end
