# frozen_string_literal: true

module Api
  module V1
    module Responses
      extend ActiveSupport::Concern

      private

      def render_resource(resource, status: :ok, include_state: false)
        render json: { data: TaskSerializer.render(resource, include_state:) }, status: status
      end

      def render_collection(records, meta: {})
        render json: { data: records, meta: meta }
      end

      def render_run(run, status: nil)
        http_status = status || (run.status == "pending" ? :accepted : :ok)
        render json: { data: TaskRunSerializer.render(run) }, status: http_status
      end

      def render_error(detail, status:, title: nil)
        render json: {
          errors: [
            {
              status: Rack::Utils.status_code(status).to_s,
              title: title || default_error_title(status),
              detail: detail
            }
          ]
        }, status: status
      end

      def render_validation_errors(record)
        render json: {
          errors: record.errors.full_messages.map do |message|
            {
              status: "422",
              title: "Validation Error",
              detail: message
            }
          end
        }, status: :unprocessable_entity
      end

      def default_error_title(status)
        case status
        when :not_found then "Not Found"
        when :unauthorized then "Unauthorized"
        when :unprocessable_entity then "Unprocessable Entity"
        else "Error"
        end
      end
    end
  end
end
