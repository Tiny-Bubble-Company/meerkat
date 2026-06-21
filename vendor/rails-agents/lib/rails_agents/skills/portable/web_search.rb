# frozen_string_literal: true

require "faraday"

module RailsAgents
  module Skills
    module Portable
      class WebSearch < Tool
        SEARCH_URL = "https://html.duckduckgo.com/html/"

        description "Search the web for current information"
        param :query, :string, description: "Search query"

        def call(query:)
          response = Faraday.get(SEARCH_URL, {q: query}, {"User-Agent" => "RailsAgents/1.0"})
          return {error: "Search failed", query: query} unless response.success?

          titles = response.body.scan(/class="result__a"[^>]*>(.*?)<\/a>/).first(5).map { |match|
            match.first.gsub(/<[^>]+>/, "").strip
          }.reject(&:empty?)

          urls = response.body.scan(/class="result__url"[^>]*>(.*?)<\/a>/).first(5).map { |match|
            match.first.gsub(/<[^>]+>/, "").strip
          }

          {query: query, results: titles.zip(urls).map { |title, url| {title:, url:} }}
        rescue StandardError => e
          {error: e.message, query: query}
        end
      end
    end
  end
end
