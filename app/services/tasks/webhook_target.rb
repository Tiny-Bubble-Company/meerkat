# frozen_string_literal: true

module Tasks
  class WebhookTarget
    DEFAULT_TOKEN = "default"

    def self.for(task)
      new(task).resolve
    end

    def self.default_token?(value)
      value.to_s.strip == DEFAULT_TOKEN
    end

    def initialize(task)
      @task = task
      @customer = task.customer
    end

    def resolve
      {
        url: resolved_url,
        headers: resolved_headers,
        uses_default: uses_default?,
        configured: resolved_url.present?
      }
    end

    private

    def uses_default?
      self.class.default_token?(@task.output_webhook)
    end

    def resolved_url
      if uses_default?
        @customer&.default_output_webhook
      else
        @task.output_webhook
      end
    end

    def resolved_headers
      return {} unless uses_default?

      normalize_headers(@customer&.default_webhook_headers)
    end

    def normalize_headers(headers)
      return {} unless headers.is_a?(Hash)

      headers.each_with_object({}) do |(key, value), normalized|
        next if key.blank? || value.blank?

        normalized[key.to_s] = value.to_s
      end
    end
  end
end
