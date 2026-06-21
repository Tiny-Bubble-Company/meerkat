# frozen_string_literal: true

class LoginController < ApplicationController
  layout "home"

  def new
    if customer_signed_in?
      redirect_to after_login_path
    end
  end

  def create
    customer = Customer.find_by(email: login_params[:email].to_s.strip.downcase)

    if customer.nil?
      flash.now[:alert] = "No account found for that email. Sign up to create one."
      render :new, status: :unprocessable_entity
      return
    end

    session[:customer_id] = customer.id
    redirect_to after_login_path, notice: "Welcome back."
  end

  private

  def login_params
    params.require(:session).permit(:email)
  end

  def after_login_path
    if current_customer.onboarding_completed?
      docs_section_path("api-keys")
    else
      onboarding_step_path(Customers::OnboardingProgress.for(current_customer).step)
    end
  end
end
