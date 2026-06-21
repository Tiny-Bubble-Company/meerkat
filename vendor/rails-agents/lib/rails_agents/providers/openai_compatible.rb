# frozen_string_literal: true

require "json"
require "faraday"

module RailsAgents
  module Providers
    class OpenAICompatible < Base
      def initialize(api_key:, base_url:, extra_headers: {}, missing_key_message:)
        raise ConfigurationError, missing_key_message if api_key.to_s.empty?
        @api_key = api_key
        @base_url = base_url
        @extra_headers = extra_headers
      end

      def chat(messages:, client_tools: [], skills: nil, model:, json: false, &block)
        tools = client_tools
        body = {
          model: model,
          messages: serialize(messages),
          tools: tools.empty? ? nil : tools.map { |t| {type: "function", function: t} }
        }.compact
        body[:response_format] = {type: "json_object"} if json

        response = connection.post("chat/completions", body.to_json)
        raise ProviderError, parse_error(response) unless response.success?

        data = JSON.parse(response.body)
        choice = data.fetch("choices").first
        message = choice.fetch("message")
        usage = data.fetch("usage", {})

        ProviderResponse.new(
          content: message["content"],
          tool_calls: (message["tool_calls"] || []).map { |tc|
            ToolCall.new(
              id: tc["id"],
              name: tc.dig("function", "name"),
              arguments: JSON.parse(tc.dig("function", "arguments") || "{}")
            )
          },
          usage: Usage.new(usage.fetch("prompt_tokens", 0), usage.fetch("completion_tokens", 0)),
          finish_reason: choice["finish_reason"],
          content_blocks: nil,
          file_ids: [],
          assistant_raw_content: nil
        )
      end

      private

      def connection
        @connection ||= Faraday.new(url: @base_url) do |f|
          f.headers["Authorization"] = "Bearer #{@api_key}"
          f.headers["Content-Type"] = "application/json"
          @extra_headers.each { |key, value| f.headers[key] = value }
        end
      end

      def serialize(messages)
        messages.map do |msg|
          h = {role: msg.role.to_s, content: msg.content}
          if msg.tool_calls&.any?
            h[:tool_calls] = msg.tool_calls.map { |tc|
              {id: tc.id, type: "function", function: {name: tc.name, arguments: tc.arguments.to_json}}
            }
          end
          h[:tool_call_id] = msg.tool_call_id if msg.tool_call_id
          h
        end
      end

      def parse_error(response)
        JSON.parse(response.body).dig("error", "message") rescue response.body
      end
    end
  end
end
