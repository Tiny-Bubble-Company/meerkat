# frozen_string_literal: true

class SignupController < ApplicationController
  layout "home"

  def new
    if customer_signed_in?
      redirect_to(current_customer.onboarding_completed? ? docs_section_path("api-keys") : onboarding_step_path("api-key"))
    end
  end

  def create
    result = Customers::Signup.call(**signup_params)
    session[:customer_id] = result[:customer].id
    session[:onboarding_step] = "api-key"
    session[:onboarding_api_key] = result[:api_key]
    redirect_to onboarding_step_path("api-key")
  rescue Customers::Signup::Error => e
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def destroy
    reset_session
    redirect_to root_path, notice: "Signed out."
  end

  private

  def signup_params
    params.require(:customer).permit(:email, :name, :company).to_h.symbolize_keys
  end
end
