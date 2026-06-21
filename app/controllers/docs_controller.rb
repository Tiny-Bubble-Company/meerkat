# frozen_string_literal: true

class DocsController < ApplicationController
  layout "docs"

  before_action :require_onboarding_complete!

  def show
    @section = resolve_section
    return if load_api_keys_section == :halt
    return if load_llm_provider_section == :halt
    nil if load_webhooks_section == :halt
  end

  private

  def load_webhooks_section
    return :continue unless @section == "webhooks"

    require_customer!
    return :halt if performed?

    :continue
  end

  def load_llm_provider_section
    return :continue unless @section == "llm-provider"

    require_customer!
    return :halt if performed?

    :continue
  end

  def resolve_section
    section = params[:section].presence || (customer_signed_in? ? "api-keys" : "quickstart")
    DocsHelper::DOCS_SECTIONS.key?(section) ? section : "quickstart"
  end

  def load_api_keys_section
    return :continue unless @section == "api-keys"

    require_customer!
    return :halt if performed?

    @api_keys = current_customer.api_keys.order(created_at: :desc)
    @new_api_key = flash[:new_api_key]
    :continue
  end
end
