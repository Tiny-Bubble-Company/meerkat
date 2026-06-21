# frozen_string_literal: true

class PagesController < ApplicationController
  layout "home"

  def home
    return unless cloud_app_host?

    if customer_signed_in?
      destination = if current_customer.onboarding_completed?
        docs_section_path("api-keys")
      else
        onboarding_step_path(Customers::OnboardingProgress.for(current_customer).step)
      end
      redirect_to destination
    else
      redirect_to signup_path
    end
  end
end
