# frozen_string_literal: true

module Docs
  class LlmProvidersController < ApplicationController
    before_action :require_customer!

    def update
      Customers::SaveLlmCredential.call(
        customer: current_customer,
        provider: llm_params[:provider],
        api_key: llm_params[:api_key],
        model: llm_params[:model]
      )

      redirect_to docs_section_path("llm-provider"), notice: "LLM provider updated."
    rescue Customers::SaveLlmCredential::Error => e
      redirect_to docs_section_path("llm-provider"), alert: e.message
    end

    private

    def llm_params
      params.require(:llm).permit(:provider, :api_key, :model)
    end
  end
end
