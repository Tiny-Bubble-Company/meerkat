# frozen_string_literal: true

require "json"
require "faraday"

module RailsAgents
  module Providers
    class Anthropic
      class Files
        FILES_BETA = "files-api-2025-04-14"
        API_VERSION = "2023-06-01"

        def initialize(api_key: RailsAgents.config.anthropic_api_key)
          raise ConfigurationError, "Set anthropic_api_key in config/initializers/rails_agents.rb" if api_key.to_s.empty?
          @api_key = api_key
        end

        def download(file_id)
          metadata = retrieve(file_id)
          response = connection.get("files/#{file_id}/content")
          raise ProviderError, "Failed to download file #{file_id}: #{response.body}" unless response.success?

          GeneratedFile.new(
            file_id: file_id,
            filename: metadata.fetch("filename"),
            content_type: metadata.fetch("mime_type"),
            data: response.body,
            path: nil
          )
        end

        def retrieve(file_id)
          response = connection.get("files/#{file_id}")
          raise ProviderError, "Failed to retrieve file #{file_id}: #{response.body}" unless response.success?

          JSON.parse(response.body)
        end

        private

        def connection
          @connection ||= Faraday.new(url: "https://api.anthropic.com/v1") do |f|
            f.headers["x-api-key"] = @api_key
            f.headers["anthropic-version"] = API_VERSION
            f.headers["anthropic-beta"] = FILES_BETA
          end
        end
      end
    end
  end
end
