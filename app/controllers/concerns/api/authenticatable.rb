# frozen_string_literal: true

module Api
  module Authenticatable
    extend ActiveSupport::Concern

    included do
      before_action :authenticate_api_key!
    end

    private

    def authenticate_api_key!
      return if skip_authentication?

      token = bearer_token
      @current_api_key = ApiKey.authenticate(token)

      return if @current_api_key

      render_error("Invalid or missing API key. Sign up at POST /api/v1/signup", status: :unauthorized, title: "Unauthorized")
    end

    def current_customer
      @current_api_key&.customer
    end

    def bearer_token
      header = request.authorization.to_s
      return header.delete_prefix("Bearer ").strip if header.start_with?("Bearer ")

      request.headers["X-Api-Key"].presence
    end

    def skip_authentication?
      false
    end
  end
end
