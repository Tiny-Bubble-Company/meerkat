# frozen_string_literal: true

module OpsHost
  extend ActiveSupport::Concern

  OPS_HOSTS = %w[ops.meerkatagents.com].freeze

  included do
    before_action :enforce_ops_host_isolation
    helper_method :ops_host?, :current_admin_user, :admin_signed_in?
  end

  private

  def ops_host?
    OPS_HOSTS.include?(request.host) ||
      (Rails.env.development? && request.host.in?(%w[localhost 127.0.0.1]))
  end

  def current_admin_user
    @current_admin_user ||= AdminUser.find_by(id: session[:admin_user_id]) if session[:admin_user_id]
  end

  def admin_signed_in?
    current_admin_user.present?
  end

  def require_admin!
    return if admin_signed_in?

    redirect_to ops_login_path, alert: "Sign in to access the admin panel."
  end

  def enforce_ops_host_isolation
    return if request.path == "/up"

    if ops_host?
      return if controller_path.start_with?("ops/")

      redirect_to ops_root_path
    elsif controller_path.start_with?("ops/")
      head :not_found
    end
  end
end
