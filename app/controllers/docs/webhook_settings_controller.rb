# frozen_string_literal: true

module Docs
  class WebhookSettingsController < ApplicationController
    before_action :require_onboarding_complete!
    before_action :require_customer!

    def update
      Customers::SaveWebhookSettings.call(
        customer: current_customer,
        url: webhook_params[:default_output_webhook],
        headers_json: webhook_params[:default_webhook_headers_json]
      )

      redirect_to docs_section_path("webhooks"), notice: "Default webhook settings saved."
    rescue Customers::SaveWebhookSettings::Error => e
      redirect_to docs_section_path("webhooks"), alert: e.message
    end

    private

    def webhook_params
      params.require(:webhook_settings).permit(:default_output_webhook, :default_webhook_headers_json)
    end
  end
end
