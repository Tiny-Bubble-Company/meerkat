# frozen_string_literal: true

module Tools
  class FetchWebpage < RailsAgents::Tool
    description "Fetch a URL and return cleaned text content suitable for extracting tracking status or page changes"
    param :url, :string, description: "URL to fetch"
    param :max_chars, :number, required: false, description: "Maximum characters to return (default 12000)"

    def call(url:, max_chars: 12_000)
      response = Faraday.get(url, nil, default_headers)
      unless response.success?
        return { error: "Fetch failed", url: url, status: response.status }
      end

      text = sanitize_html(response.body)
      {
        url: url,
        status: response.status,
        content: text[0, max_chars.to_i],
        fetched_at: Time.current.iso8601
      }
    rescue StandardError => e
      { error: e.message, url: url }
    end

    private

    def default_headers
      {
        "User-Agent" => "Meerkat/1.0 (+https://github.com/meerkat)",
        "Accept" => "text/html,application/xhtml+xml"
      }
    end

    def sanitize_html(body)
      body
        .gsub(/<script.*?>.*?<\/script>/m, " ")
        .gsub(/<style.*?>.*?<\/style>/m, " ")
        .gsub(/<[^>]+>/, " ")
        .gsub(/\s+/, " ")
        .strip
    end
  end
end
