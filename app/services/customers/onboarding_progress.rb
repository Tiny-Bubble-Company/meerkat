# frozen_string_literal: true

module Customers
  class OnboardingProgress
    STEPS = OnboardingController::STEPS

    def self.for(customer)
      new(customer)
    end

    def initialize(customer)
      @customer = customer
    end

    def step
      @step ||= compute_step
    end

    def task
      @task ||= @customer.tasks.order(created_at: :desc).first
    end

    def run
      @run ||= task&.task_runs&.order(created_at: :desc)&.first
    end

    def task_id
      task&.id
    end

    def run_id
      run&.id
    end

    def completed?
      @customer.onboarding_completed?
    end

    def sync_session!(session)
      return if completed?

      session[:onboarding_step] = step
      session[:onboarding_task_id] = task_id if task_id
      session[:onboarding_run_id] = run_id if run_id
    end

    private

    def compute_step
      return nil if completed?

      if run&.status.in?(%w[succeeded failed])
        "success"
      elsif run&.status.in?(%w[pending running])
        "waiting"
      elsif task.present?
        "run-task"
      elsif @customer.llm_configured?
        "create-task"
      elsif @customer.api_keys.active.exists?
        "llm-provider"
      else
        "api-key"
      end
    end
  end
end
