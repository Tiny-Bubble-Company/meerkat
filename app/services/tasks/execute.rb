# frozen_string_literal: true

module Tasks
  class Execute
    def self.call(task:, run: nil)
      new(task:, run:).call
    end

    def initialize(task:, run: nil)
      @task = task
      @run = run
    end

    def call
      return ExecuteOnboardingDemo.call(task: @task, run: @run) if onboarding_demo?

      return if @task.status != "active"

      @run ||= @task.task_runs.create!(status: "pending")
      @run.mark_running!

      Report.call(
        task: @task,
        run: @run,
        event_type: "run_started",
        payload: { run_id: @run.id, task_id: @task.id, task_type: @task.task_type }
      )

      result = Agents::RunForCustomer.call(
        customer: @task.customer,
        input: build_agent_input,
        **build_agent_context
      )

      if result.success
        handle_success(result)
      else
        handle_failure(result.error)
      end

      @run
    rescue StandardError => e
      handle_failure(e.message)
      @run
    ensure
      finalize_task_lifecycle
    end

    private

    def build_agent_input
      input = {
        task_type: @task.task_type,
        task_description: @task.description,
        input_params: @task.input_params,
        previous_state: @task.last_known_state,
        run_number: @task.run_count + 1
      }

      if @task.output_format.present?
        input[:output_format] = @task.output_format
        input[:output_format_instruction] = output_format_instruction
      end

      input
    end

    def output_format_instruction
      return @task.output_format if @task.custom_output_format_instruction?

      case @task.output_format
      when "compact"
        "Shape findings for a compact webhook: focus on summary and the most important fields only."
      when "flat"
        "Shape findings as flat snake_case keys suitable for merging into a webhook root object."
      when "findings_only"
        "Return findings as the primary payload content with no wrapper fields beyond summary and change_detected."
      when "minimal"
        "Return only a short summary and change_detected flag in findings."
      else
        nil
      end
    end

    def build_agent_context
      {
        task_id: @task.id,
        task_run_id: @run.id,
        task_type: @task.task_type,
        output_webhook: @task.output_webhook,
        output_format: @task.output_format
      }
    end

    def handle_success(result)
      structured = result.data || {}
      findings = structured["findings"] || structured[:findings] || {}
      change_detected = detect_change?(findings, structured)
      should_report = should_report?(structured, change_detected)

      @run.mark_succeeded!(
        output: result.output,
        structured_output: structured,
        usage: usage_hash(result.usage),
        change_detected: change_detected
      )

      @task.update!(
        last_known_state: findings.presence || @task.last_known_state,
        last_run_at: Time.current,
        run_count: @task.run_count + 1,
        consecutive_failures: 0
      )

      Report.call(
        task: @task,
        run: @run,
        event_type: event_type_for_success(change_detected),
        payload: build_report_payload(structured, change_detected:),
        deliver_webhook: should_report
      )
    end

    def handle_failure(error_message)
      @run&.mark_failed!(error: error_message)

      failures = @task.consecutive_failures + 1
      attrs = {
        last_run_at: Time.current,
        consecutive_failures: failures
      }

      if @task.one_off?
        attrs[:status] = "failed"
      elsif failures >= failure_threshold
        attrs[:status] = "failed"
      end

      @task.update!(attrs)

      Report.call(
        task: @task,
        run: @run,
        event_type: "run_failed",
        payload: { error: error_message, run_id: @run&.id, task_type: @task.task_type },
        deliver_webhook: true
      )
    end

    def should_report?(structured, change_detected)
      if @task.one_off?
        structured.fetch("should_report", structured.fetch(:should_report, true))
      else
        structured.fetch("should_report", structured.fetch(:should_report, change_detected))
      end
    end

    def event_type_for_success(change_detected)
      if @task.one_off?
        "run_completed"
      else
        change_detected ? "status_changed" : "run_completed"
      end
    end

    def detect_change?(findings, structured)
      return false if @task.one_off?

      explicit = structured["change_detected"]
      return explicit if explicit == true || explicit == false

      previous = @task.last_known_state
      return true if previous.blank? && findings.present?

      findings.to_json != previous.to_json
    end

    def build_report_payload(structured, change_detected:)
      {
        task_id: @task.id,
        task_type: @task.task_type,
        run_id: @run.id,
        change_detected: change_detected,
        summary: structured["summary"] || structured[:summary],
        findings: structured["findings"] || structured[:findings],
        input_params: @task.input_params,
        finished_at: @run.finished_at
      }
    end

    def usage_hash(usage)
      {
        input_tokens: usage.input_tokens,
        output_tokens: usage.output_tokens
      }
    end

    def finalize_task_lifecycle
      return unless @run&.status.in?(%w[succeeded failed])

      if @task.one_off?
        @task.update!(status: @run.status == "succeeded" ? "completed" : "failed")
      elsif @task.active?
        @task.schedule_next_run!(from: Time.current)
      end
    end

    def failure_threshold
      ENV.fetch("MEERKAT_FAILURE_THRESHOLD", 5).to_i
    end

    def onboarding_demo?
      return true if @task.metadata.is_a?(Hash) && @task.metadata["onboarding_demo"]
      return false if @task.customer.onboarding_completed?

      @task.one_off? && @task.customer.tasks.one_off.count == 1
    end
  end
end
