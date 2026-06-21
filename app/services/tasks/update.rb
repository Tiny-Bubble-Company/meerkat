# frozen_string_literal: true

module Tasks
  class Update
    class Error < Tasks::Error; end

    UPDATABLE = %i[description input_params frequency output_webhook output_format metadata status].freeze

    def self.call(task:, **attributes)
      new(task:, attributes:).call
    end

    def initialize(task:, attributes:)
      @task = task
      @attributes = attributes.symbolize_keys.slice(*UPDATABLE).reject { |_, value| value.nil? }
    end

    def call
      raise Error, "No attributes to update" if @attributes.empty?
      validate_task_type_constraints!

      frequency_changed = @attributes.key?(:frequency)
      if frequency_changed
        @attributes[:frequency_seconds] = FrequencyParser.parse!(@attributes[:frequency])
      end

      @task.assign_attributes(@attributes)

      if frequency_changed && @task.recurring? && @task.active?
        @task.next_run_at = Time.current + @task.frequency_seconds.seconds
      end

      @task.save!

      Report.call(
        task: @task,
        event_type: "task_updated",
        payload: {
          task_id: @task.id,
          updated_attributes: @attributes.keys.map(&:to_s)
        }
      )

      @task
    rescue FrequencyParser::Error => e
      raise Error, e.message
    end

    private

    def validate_task_type_constraints!
      if @task.one_off? && @attributes.key?(:frequency)
        raise Error, "frequency cannot be set on one_off tasks"
      end

      if @task.recurring? && @attributes.key?(:frequency) && @attributes[:frequency].blank?
        raise Error, "frequency cannot be blank for recurring tasks"
      end
    end
  end
end
