# frozen_string_literal: true

module Api
  class BaseController < ActionController::API
    include Api::V1::Responses
    include Api::Authenticatable

    rescue_from ActiveRecord::RecordNotFound do
      render_error("Resource not found", status: :not_found)
    end
  end
end
