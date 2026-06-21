# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CloudRouting
  include OpsHost
  include DeployHelper

  helper_method :current_customer, :customer_signed_in?, :api_base_url,
                :marketing_site_host?, :cloud_app_host?, :ops_host?, :cloud_app_url,
                :meerkat_cloud_url, :meerkat_website_url, :github_repo_url,
                :current_admin_user, :admin_signed_in?

  protect_from_forgery with: :exception

  private

  def current_customer
    @current_customer ||= Customer.find_by(id: session[:customer_id]) if session[:customer_id]
  end

  def customer_signed_in?
    current_customer.present?
  end

  def require_customer!
    return if customer_signed_in?

    redirect_to signup_path, alert: "Sign up to manage API keys."
  end

  def require_onboarding_complete!
    return unless customer_signed_in?
    return if current_customer.onboarding_completed?

    step = session[:onboarding_step].presence || "api-key"
    redirect_to onboarding_step_path(step)
  end

  def api_base_url
    "#{request.base_url}/api/v1"
  end
end
