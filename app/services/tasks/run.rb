# frozen_string_literal: true

module Tasks
  class Run
    class Error < Tasks::Error; end

    def self.call(task:, async: true)
      new(task:, async:).call
    end

    def initialize(task:, async: true)
      @task = task
      @async = async
    end

    def call
      validate_runnable!

      if @async
        enqueue_run
      else
        Execute.call(task: @task)
      end
    end

    private

    def validate_runnable!
      @task.update!(status: "active") if @task.one_off? && @task.status == "failed"

      raise Error, "One-off task is already completed" if @task.one_off? && @task.status == "completed"
      raise Error, "Task is archived" if @task.status == "archived"
      raise Error, "Task is not active" unless @task.active?
      raise Error, "A run is already in progress" if @task.task_runs.exists?(status: "running")
      raise Error, llm_setup_message unless runnable_llm_credentials?
    end

    def runnable_llm_credentials?
      @task.customer.llm_configured? || development_platform_llm?
    end

    def development_platform_llm?
      Rails.env.development? &&
        RailsAgents.config.api_key_for(RailsAgents.config.default_provider).present?
    end

    def llm_setup_message
      "Connect an LLM provider before running tasks. Add your Anthropic or OpenAI key in settings."
    end

    def enqueue_run
      run = @task.task_runs.create!(status: "pending")
      ExecuteTaskJob.perform_later(@task.id, run.id)
      run
    end
  end
end
