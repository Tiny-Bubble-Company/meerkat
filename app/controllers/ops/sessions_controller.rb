# frozen_string_literal: true

module Ops
  class SessionsController < ApplicationController
    skip_before_action :require_admin!, only: %i[new create]
    layout "ops"

    def new
      redirect_to ops_root_path if admin_signed_in?
    end

    def create
      admin = AdminUser.find_by(email: session_params[:email].to_s.strip.downcase)

      if admin&.authenticate(session_params[:password])
        reset_session
        session[:admin_user_id] = admin.id
        redirect_to ops_root_path, notice: "Signed in."
      else
        flash.now[:alert] = "Invalid email or password."
        render :new, status: :unprocessable_entity
      end
    end

    def destroy
      reset_session
      redirect_to ops_login_path, notice: "Signed out."
    end

    private

    def session_params
      params.require(:session).permit(:email, :password)
    end
  end
end
