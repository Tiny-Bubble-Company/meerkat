# frozen_string_literal: true

module Docs
  class ApiKeysController < ApplicationController
    before_action :require_customer!
    before_action :require_onboarding_complete!

    def create
      _api_key, raw_token = ApiKey.generate!(
        customer: current_customer,
        name: params.fetch(:name, "Default")
      )

      flash[:new_api_key] = raw_token
      redirect_to docs_section_path("api-keys"), notice: "New API key generated."
    end

    def destroy
      api_key = current_customer.api_keys.active.find(params[:id])
      api_key.revoke!
      redirect_to docs_section_path("api-keys"), notice: "API key revoked."
    end
  end
end
