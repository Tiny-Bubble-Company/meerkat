# frozen_string_literal: true

module Api
  module V1
    class ApiKeysController < Api::BaseController
      def index
        keys = current_customer.api_keys.order(created_at: :desc)
        render_collection(
          keys.map { |key| ApiKeySerializer.render(key) },
          meta: { count: keys.size }
        )
      end

      def create
        api_key, raw_token = ApiKey.generate!(
          customer: current_customer,
          name: api_key_name
        )

        render json: {
          data: ApiKeySerializer.render(api_key).merge(token: raw_token),
          meta: { message: "Store this key securely. It will not be shown again." }
        }, status: :created
      end

      def destroy
        api_key = current_customer.api_keys.active.find(params[:id])
        api_key.revoke!
        head :no_content
      end

      private

      def api_key_name
        params.dig(:api_key, :name) || params[:name] || "Default"
      end
    end
  end
end
