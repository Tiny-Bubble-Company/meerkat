# frozen_string_literal: true

class OnboardingController < ApplicationController
  layout "onboarding"

  STEPS = %w[api-key llm-provider create-task run-task waiting success].freeze

  before_action :require_customer!
  before_action :redirect_if_completed, except: :complete
  before_action :enforce_step_order, only: :show
  before_action :ensure_task_for_task_steps, only: :show
  before_action :ensure_run_for_run_steps, only: :show

  def show
    @step = normalized_step(params[:step])
    load_step_data
    render @step.tr("-", "_")
  end

  def acknowledge_key
    unless session[:onboarding_api_key].present? || current_customer.api_keys.active.exists?
      redirect_to onboarding_step_path("api-key"), alert: "Your API key is required before continuing."
      return
    end

    session.delete(:onboarding_api_key)
    advance_to!("llm-provider")
    redirect_to onboarding_step_path("llm-provider")
  end

  def save_llm_provider
    Customers::SaveLlmCredential.call(
      customer: current_customer,
      provider: llm_params[:provider],
      api_key: llm_params[:api_key],
      model: llm_params[:model]
    )

    advance_to!("create-task")
    redirect_to onboarding_step_path("create-task"), notice: "LLM provider connected."
  rescue Customers::SaveLlmCredential::Error => e
    flash[:alert] = e.message
    redirect_to onboarding_step_path("llm-provider")
  end

  def create_task
    webhook_url = task_params[:output_webhook].presence || onboarding_test_webhook_url

    task = Tasks::Create.call(
      customer: current_customer,
      task_type: "one_off",
      description: task_params[:description],
      input_params: { url: task_params[:url] },
      output_webhook: webhook_url,
      run_immediately: false
    )

    session[:onboarding_task_id] = task.id
    advance_to!("run-task")
    redirect_to onboarding_step_path("run-task"), notice: "Task created."
  rescue Tasks::Create::Error, ActiveRecord::RecordInvalid => e
    message = e.respond_to?(:record) ? e.record.errors.full_messages.join(", ") : e.message
    flash[:alert] = message
    redirect_to onboarding_step_path("create-task")
  end

  def run_task
    task = onboarding_task!
    validate_task_runnable!(task)

    run = task.task_runs.create!(status: "pending")
    session[:onboarding_run_id] = run.id
    advance_to!("waiting")
    redirect_to onboarding_step_path("waiting")
  rescue Tasks::Run::Error => e
    flash[:alert] = e.message
    redirect_to onboarding_step_path("run-task")
  end

  def process_run
    run = onboarding_run
    return head :not_found unless run

    run.reload
    return head :no_content unless run.status == "pending"

    Tasks::Execute.call(task: run.task, run: run)
    head :no_content
  end

  def run_status
    run = onboarding_run
    return head :not_found unless run

    run.reload
    advance_to!("success") if run.status.in?(%w[succeeded failed])

    render json: {
      status: run.status,
      finished: run.status.in?(%w[succeeded failed]),
      succeeded: run.status == "succeeded",
      error: run.error,
      summary: run_summary(run),
      webhook_received: latest_onboarding_webhook_delivery.present?,
      webhook_payload: latest_onboarding_webhook_delivery&.payload
    }
  end

  def complete
    current_customer.complete_onboarding!
    clear_onboarding_session!
    redirect_to docs_section_path("quickstart"), notice: "You're all set. Explore the API docs anytime."
  end

  private

  def redirect_if_completed
    return unless current_customer.onboarding_completed?

    redirect_to docs_section_path("api-keys")
  end

  def enforce_step_order
    requested = normalized_step(params[:step])
    allowed = session[:onboarding_step].presence || "api-key"

    return if step_index(requested) <= step_index(allowed)
    return if requested == "success" && onboarding_run&.status.in?(%w[succeeded failed])

    redirect_to onboarding_step_path(allowed)
  end

  def ensure_task_for_task_steps
    step = normalized_step(params[:step])
    return unless step.in?(%w[run-task waiting success])

    onboarding_task!
  rescue ActiveRecord::RecordNotFound
    redirect_to onboarding_step_path("create-task"), alert: "Create a task first."
  end

  def ensure_run_for_run_steps
    step = normalized_step(params[:step])
    return unless step.in?(%w[waiting success])

    redirect_to onboarding_step_path("run-task"), alert: "Run your task first." unless onboarding_run
  end

  def normalized_step(step)
    slug = step.to_s.presence || session[:onboarding_step].presence || "api-key"
    STEPS.include?(slug) ? slug : "api-key"
  end

  def step_index(step)
    STEPS.index(step) || 0
  end

  def advance_to!(step)
    session[:onboarding_step] = step
  end

  def load_step_data
    case @step
    when "api-key"
      @api_key = session[:onboarding_api_key].presence || flash[:new_api_key]
      session[:onboarding_api_key] ||= @api_key if @api_key.present?
      advance_to!("api-key") if session[:onboarding_step].blank?
    when "llm-provider"
      @llm_providers = Customer::LLM_PROVIDERS
      @default_models = Customer::DEFAULT_LLM_MODELS
      @llm_configured = current_customer.llm_configured?
    when "create-task"
      @sample_payload = onboarding_task_sample_payload
      @default_webhook_url = onboarding_test_webhook_url
    when "run-task"
      @task = onboarding_task!
    when "waiting"
      @run = onboarding_run
    when "success"
      @run = onboarding_run
      @task = onboarding_task!
      @webhook_delivery = latest_onboarding_webhook_delivery
    end
  end

  def onboarding_task!
    current_customer.tasks.find(session[:onboarding_task_id])
  end

  def onboarding_run
    return unless session[:onboarding_run_id]

    TaskRun.joins(:task).find_by(id: session[:onboarding_run_id], tasks: { customer_id: current_customer.id })
  end

  def task_params
    params.require(:task).permit(:description, :url, :output_webhook)
  end

  def llm_params
    params.require(:llm).permit(:provider, :api_key, :model)
  end

  def latest_onboarding_webhook_delivery
    run_id = session[:onboarding_run_id]
    delivery = OnboardingWebhookDelivery.latest_for_run(
      customer: current_customer,
      task_run_id: run_id
    ).first

    return delivery if delivery.present?

    run = onboarding_run
    return nil unless run

    current_customer.onboarding_webhook_deliveries
      .where("created_at >= ?", run.created_at)
      .recent
      .first
  end

  def run_summary(run)
    return run.structured_output if run.structured_output.is_a?(String)
    return run.structured_output["summary"] if run.structured_output.is_a?(Hash)

    run.output.to_s.truncate(200)
  rescue StandardError
    nil
  end

  def clear_onboarding_session!
    session.delete(:onboarding_step)
    session.delete(:onboarding_api_key)
    session.delete(:onboarding_task_id)
    session.delete(:onboarding_run_id)
  end

  def validate_task_runnable!(task)
    task.update!(status: "active") if task.one_off? && task.status == "failed"
    raise Tasks::Run::Error, "One-off task is already completed" if task.one_off? && task.status == "completed"
    raise Tasks::Run::Error, "Task is archived" if task.status == "archived"
    raise Tasks::Run::Error, "Task is not active" unless task.active?
    raise Tasks::Run::Error, "A run is already in progress" if task.task_runs.exists?(status: "running")
    raise Tasks::Run::Error, "Connect an LLM provider before running tasks" unless task.customer.llm_configured? || development_platform_llm?
  end

  def development_platform_llm?
    Rails.env.development? &&
      RailsAgents.config.api_key_for(RailsAgents.config.default_provider).present?
  end
end
