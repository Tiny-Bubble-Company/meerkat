# frozen_string_literal: true

module Webhooks
  class PayloadFormatter
    def self.call(event:, format: nil)
      new(event:, format:).call
    end

    def initialize(event:, format: nil)
      @event = event
      @format = format.presence || "default"
      @data = event.payload.deep_symbolize_keys
    end

    def call
      case @format
      when "compact" then compact_payload
      when "flat" then flat_payload
      when "findings_only" then findings_only_payload
      when "minimal" then minimal_payload
      else default_payload
      end
    end

    private

    def base_meta
      {
        event: @event.event_type,
        task_id: @event.task_id,
        task_run_id: @event.task_run_id,
        occurred_at: @event.created_at.iso8601
      }
    end

    def default_payload
      base_meta.merge(data: @event.payload)
    end

    def compact_payload
      base_meta.merge(
        summary: @data[:summary],
        change_detected: @data[:change_detected],
        findings: @data[:findings]
      ).compact
    end

    def flat_payload
      findings = (@data[:findings] || {}).deep_symbolize_keys
      base_meta.merge(
        summary: @data[:summary],
        change_detected: @data[:change_detected],
        **findings
      ).compact
    end

    def findings_only_payload
      (@data[:findings].presence || @data.except(:task_id, :task_type, :run_id, :input_params, :finished_at)).as_json
    end

    def minimal_payload
      {
        event: @event.event_type,
        task_id: @event.task_id,
        summary: @data[:summary],
        change_detected: @data[:change_detected]
      }.compact
    end
  end
end
