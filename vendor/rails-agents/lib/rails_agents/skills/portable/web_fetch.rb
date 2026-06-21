# frozen_string_literal: true

require "faraday"

module RailsAgents
  module Skills
    module Portable
      class WebFetch < Tool
        description "Fetch and read the text content of a web page"
        param :url, :string, description: "URL to fetch"

        def call(url:)
          response = Faraday.get(url, nil, {"User-Agent" => "RailsAgents/1.0"})
          return {error: "Fetch failed", url: url, status: response.status} unless response.success?

          text = response.body.gsub(/<script.*?>.*?<\/script>/m, "")
            .gsub(/<style.*?>.*?<\/style>/m, "")
            .gsub(/<[^>]+>/, " ")
            .gsub(/\s+/, " ")
            .strip

          {url: url, content: text[0, 8_000]}
        rescue StandardError => e
          {error: e.message, url: url}
        end
      end
    end
  end
end
