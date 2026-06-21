# frozen_string_literal: true

class OnboardingInboxController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :create

  def create
    customer_id = OnboardingWebhookToken.verify(params[:token])
    return head :unauthorized unless customer_id

    customer = Customer.find_by(id: customer_id)
    return head :not_found unless customer

    payload = parse_payload
    task_run_id = extract_task_run_id(payload)

    OnboardingWebhookDelivery.create!(
      customer: customer,
      task_run_id: task_run_id,
      payload: payload
    )

    head :ok
  rescue JSON::ParserError
    head :bad_request
  end

  def status
    require_customer!

    run_id = session[:onboarding_run_id]
    delivery = OnboardingWebhookDelivery.latest_for_run(
      customer: current_customer,
      task_run_id: run_id
    ).first

    if delivery.nil? && run_id.present?
      run = TaskRun.joins(:task).find_by(id: run_id, tasks: { customer_id: current_customer.id })
      delivery = current_customer.onboarding_webhook_deliveries
        .where("created_at >= ?", run.created_at)
        .recent
        .first if run
    end

    if delivery
      render json: {
        received: true,
        received_at: delivery.created_at.iso8601,
        payload: delivery.payload
      }
    else
      render json: { received: false }
    end
  end

  private

  def parse_payload
    body = request.raw_post.presence
    body ? JSON.parse(body) : {}
  end

  def extract_task_run_id(payload)
    id = payload["task_run_id"] || payload.dig("data", "task_run_id")
    id.presence&.to_i
  end
end
