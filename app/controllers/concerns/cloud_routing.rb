# frozen_string_literal: true

module CloudRouting
  extend ActiveSupport::Concern

  MARKETING_HOSTS = %w[meerkatagents.com www.meerkatagents.com].freeze
  OPS_HOSTS = OpsHost::OPS_HOSTS

  included do
    before_action :redirect_marketing_host_to_cloud_app
  end

  private

  def marketing_site_host?
    MARKETING_HOSTS.include?(request.host)
  end

  def cloud_app_host?
    !marketing_site_host? && !ops_host?
  end

  def ops_host?
    OPS_HOSTS.include?(request.host) ||
      (Rails.env.development? && request.host.in?(%w[localhost 127.0.0.1]))
  end

  def redirect_marketing_host_to_cloud_app
    return unless marketing_site_host?
    return if allowed_on_marketing_host?

    redirect_to cloud_app_url(request.fullpath), allow_other_host: true
  end

  def allowed_on_marketing_host?
    request.path == "/up" ||
      controller_path.in?(%w[pages use_cases]) ||
      request.path.start_with?("/marketing/")
  end

  def cloud_app_url(path = "/")
    base = meerkat_cloud_url.chomp("/")
    normalized = path.start_with?("/") ? path : "/#{path}"
    "#{base}#{normalized}"
  end
end
