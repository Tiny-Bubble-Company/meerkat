# frozen_string_literal: true

module Tasks
  class Replace
    class Error < Tasks::Error; end

    REQUIRED = %i[description input_params output_webhook].freeze
    RECURRING_REQUIRED = %i[frequency].freeze

    def self.call(task:, **attributes)
      new(task:, attributes:).call
    end

    def initialize(task:, attributes:)
      @task = task
      @attributes = attributes.symbolize_keys
    end

    def call
      required = @task.recurring? ? REQUIRED + RECURRING_REQUIRED : REQUIRED
      missing = required.reject { |key| @attributes.key?(key) && !@attributes[key].nil? }
      raise Error, "Missing required fields: #{missing.join(', ')}" if missing.any?

      Update.call(
        task: @task,
        description: @attributes[:description],
        input_params: @attributes[:input_params] || {},
        frequency: @task.recurring? ? @attributes[:frequency] : nil,
        output_webhook: @attributes.fetch(:output_webhook, @task.output_webhook),
        output_format: @attributes.fetch(:output_format, @task.output_format),
        metadata: @attributes.fetch(:metadata, @task.metadata),
        status: @attributes.fetch(:status, @task.status)
      )
    end
  end
end
