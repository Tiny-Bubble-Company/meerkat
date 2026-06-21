# frozen_string_literal: true

module Api
  module V1
    class OpenapiController < Api::BaseController
      skip_before_action :authenticate_api_key!, raise: false

      def show
        send_file(
          Rails.root.join("openapi/openapi.yaml"),
          type: "application/yaml",
          disposition: "inline",
          filename: "openapi.yaml"
        )
      end
    end
  end
end
