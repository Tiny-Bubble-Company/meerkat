# frozen_string_literal: true

module Customers
  class SaveWebhookSettings
    class Error < StandardError; end

    def self.call(customer:, url:, headers_json: nil)
      new(customer:, url:, headers_json:).call
    end

    def initialize(customer:, url:, headers_json: nil)
      @customer = customer
      @url = url.to_s.strip.presence
      @headers_json = headers_json.to_s.strip.presence
    end

    def call
      headers = parse_headers!(@headers_json)

      if @url.present? && !valid_url?(@url)
        raise Error, "Default webhook URL must be a valid http or https URL"
      end

      @customer.update!(
        default_output_webhook: @url,
        default_webhook_headers: headers
      )

      @customer
    end

    private

    def parse_headers!(raw)
      return {} if raw.blank?

      parsed = JSON.parse(raw)
      raise Error, "Webhook headers must be a JSON object" unless parsed.is_a?(Hash)

      parsed.each_with_object({}) do |(key, value), headers|
        key = key.to_s.strip
        next if key.blank?

        headers[key] = value.to_s
      end
    rescue JSON::ParserError
      raise Error, "Webhook headers must be valid JSON"
    end

    def valid_url?(url)
      uri = URI.parse(url)
      uri.is_a?(URI::HTTP) && uri.host.present?
    rescue URI::InvalidURIError
      false
    end
  end
end
