# frozen_string_literal: true

module Ops
  class UsersController < ApplicationController
    def index
      scope = Customer.order(created_at: :desc)
      scope = scope.where("email ILIKE ?", "%#{params[:q]}%") if params[:q].present?
      @users, @page, @per, @total = paginate(scope)
    end

    def show
      @user = Customer.find(params[:id])
      @tasks = @user.tasks.order(created_at: :desc).limit(20)
      @api_keys = @user.api_keys.order(created_at: :desc)
    end
  end
end
