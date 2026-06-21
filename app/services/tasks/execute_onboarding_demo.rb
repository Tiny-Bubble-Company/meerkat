# frozen_string_literal: true

module Tasks
  class ExecuteOnboardingDemo
    USER_AGENT = "Meerkat/1.0 (+https://github.com/Tiny-Bubble-Company/meerkat)"

    def self.call(task:, run: nil)
      new(task:, run:).call
    end

    def initialize(task:, run: nil)
      @task = task
      @run = run
    end

    def call
      return if @task.status != "active"

      @run ||= @task.task_runs.create!(status: "pending")
      @run.mark_running!

      Report.call(
        task: @task,
        run: @run,
        event_type: "run_started",
        payload: { run_id: @run.id, task_id: @task.id, task_type: @task.task_type }
      )

      url = @task.input_params["url"].presence || @task.input_params[:url].presence || "https://meerkatagents.com/"
      fetch_result = fetch_page(url)

      if fetch_result[:error].present?
        fail_run("Could not fetch #{url}: #{fetch_result[:error]}")
        return @run
      end

      page_title = fetch_result[:page_title].presence || "Meerkat"
      findings = {
        "url" => url,
        "page_title" => page_title,
        "fetched_at" => fetch_result[:fetched_at]
      }
      structured = {
        "summary" => "Fetched page title from #{url}",
        "findings" => findings,
        "change_detected" => false,
        "should_report" => true,
        "tools_used" => [ "fetch_webpage" ]
      }

      @run.mark_succeeded!(
        output: structured.to_json,
        structured_output: structured,
        usage: { input_tokens: 0, output_tokens: 0 },
        change_detected: false
      )

      @task.update!(
        last_known_state: findings,
        last_run_at: Time.current,
        run_count: @task.run_count + 1,
        consecutive_failures: 0,
        status: "completed"
      )

      Report.call(
        task: @task,
        run: @run,
        event_type: "run_completed",
        payload: {
          task_id: @task.id,
          task_type: @task.task_type,
          run_id: @run.id,
          change_detected: false,
          summary: structured["summary"],
          findings: findings,
          input_params: @task.input_params,
          finished_at: @run.finished_at
        },
        deliver_webhook: true
      )

      @run
    rescue StandardError => e
      fail_run(e.message)
      @run
    end

    private

    def fetch_page(url)
      response = Faraday.get(url, nil, {
        "User-Agent" => USER_AGENT,
        "Accept" => "text/html,application/xhtml+xml"
      })

      return { error: "HTTP #{response.status}" } unless response.success?

      body = response.body.to_s
      {
        page_title: body[/<title[^>]*>(.*?)<\/title>/im, 1]&.strip,
        fetched_at: Time.current.iso8601
      }
    rescue StandardError => e
      { error: e.message }
    end

    def fail_run(message)
      @run&.mark_failed!(error: message)
      @task.update!(
        last_run_at: Time.current,
        consecutive_failures: @task.consecutive_failures + 1,
        status: "failed"
      )

      Report.call(
        task: @task,
        run: @run,
        event_type: "run_failed",
        payload: { error: message, run_id: @run&.id, task_type: @task.task_type },
        deliver_webhook: true
      )
    end
  end
end
