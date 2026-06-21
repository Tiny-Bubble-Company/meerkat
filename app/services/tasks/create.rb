# frozen_string_literal: true

module Tasks
  class Create
    class Error < Tasks::Error; end

    def self.call(**attributes)
      new(**attributes).call
    end

    def initialize(task_type:, description:, input_params:, frequency: nil, output_webhook: nil, output_format: nil, metadata: {}, run_immediately: nil, customer: nil)
      @task_type = task_type.to_s
      @description = description
      @input_params = input_params || {}
      @frequency = frequency
      @output_webhook = output_webhook
      @output_format = OutputFormat.normalize(output_format)
      @metadata = metadata || {}
      @run_immediately = run_immediately.nil? ? one_off? : run_immediately
      @customer = customer
    end

    def call
      validate!
      normalize_output_webhook!

      task = Task.create!(build_attributes)

      Report.call(
        task: task,
        event_type: "task_registered",
        payload: {
          task_id: task.id,
          task_type: task.task_type,
          description: task.description,
          input_params: task.input_params,
          frequency: task.frequency,
          output_webhook: task.output_webhook,
          output_format: task.output_format
        }
      )

      ExecuteTaskJob.perform_later(task.id) if @run_immediately

      task
    rescue FrequencyParser::Error => e
      raise Error, e.message
    end

    private

    def validate!
      raise Error, "task_type must be recurring or one_off" unless Task::TASK_TYPES.include?(@task_type)
      raise Error, "frequency is required for recurring tasks" if recurring? && @frequency.blank?
      raise Error, "frequency is not allowed for one_off tasks" if one_off? && @frequency.present?
      raise Error, "output_webhook is required" if @output_webhook.blank?
      if Tasks::WebhookTarget.default_token?(@output_webhook) && !@customer&.default_webhook_configured?
        raise Error, "default webhook is not configured for this account"
      end
      OutputFormat.validate!(@output_format)
    rescue ArgumentError => e
      raise Error, e.message
    end

    def build_attributes
      attrs = {
        task_type: @task_type,
        description: @description,
        input_params: @input_params,
        output_webhook: @output_webhook,
        output_format: @output_format,
        metadata: @metadata,
        customer: @customer
      }

      if recurring?
        frequency_seconds = FrequencyParser.parse!(@frequency)
        attrs[:frequency] = @frequency
        attrs[:frequency_seconds] = frequency_seconds
        attrs[:next_run_at] = @run_immediately ? Time.current : Time.current + frequency_seconds.seconds
      else
        attrs[:frequency] = nil
        attrs[:frequency_seconds] = nil
        attrs[:next_run_at] = nil
      end

      attrs
    end

    def recurring?
      @task_type == "recurring"
    end

    def one_off?
      @task_type == "one_off"
    end

    def normalize_output_webhook!
      return if @output_webhook.present?

      @output_webhook = Tasks::WebhookTarget::DEFAULT_TOKEN if @customer&.default_webhook_configured?
    end
  end
end
