# frozen_string_literal: true

module Api
  module V1
    class SignupController < Api::BaseController
      skip_before_action :authenticate_api_key!, raise: false

      def create
        result = Customers::Signup.call(**signup_params)

        render json: {
          data: {
            customer: CustomerSerializer.render(result[:customer]),
            api_key: result[:api_key]
          },
          meta: {
            message: "Store your API key securely. It will not be shown again."
          }
        }, status: :created
      rescue Customers::Signup::Error => e
        render_error(e.message, status: :unprocessable_entity, title: "Signup Failed")
      end

      private

      def signup_params
        params.require(:customer).permit(:email, :name, :company).to_h.symbolize_keys
      end
    end
  end
end
