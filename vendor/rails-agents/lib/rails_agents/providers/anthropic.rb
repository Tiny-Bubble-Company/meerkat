# frozen_string_literal: true

require "json"
require "faraday"

module RailsAgents
  module Providers
    class Anthropic < Base
      API_VERSION = "2023-06-01"

      def initialize(api_key: RailsAgents.config.anthropic_api_key)
        raise ConfigurationError, "Set anthropic_api_key in config/initializers/rails_agents.rb" if api_key.to_s.empty?
        @api_key = api_key
      end

      def chat(messages:, client_tools: [], skills: nil, model:, json: false, &block)
        anthropic_skills = skills&.anthropic_request || {}
        body = build_body(messages:, client_tools:, skills: anthropic_skills, model:)

        response = connection(anthropic_skills[:beta_headers]).post("messages", body.to_json)
        raise ProviderError, parse_error(response) unless response.success?

        parse_response(JSON.parse(response.body), json:)
      end

      def files = @files ||= Files.new(api_key: @api_key)

      private

      def build_body(messages:, client_tools:, skills:, model:)
        system, conversation = split_system(messages)
        tools = client_tools.map { |tool|
          {name: tool[:name], description: tool[:description], input_schema: tool[:parameters]}
        }
        tools.concat(skills.fetch(:server_tools, []))

        {
          model: model,
          max_tokens: 16_384,
          system: system,
          messages: serialize(conversation),
          tools: tools.empty? ? nil : tools,
          container: skills[:container]
        }.compact
      end

      def parse_response(data, json:)
        content_blocks = data.fetch("content")
        text = Skills::AnthropicContent.extract_text(content_blocks)
        text = "{}" if json && text.blank?
        tool_blocks = content_blocks.select { |block| block["type"] == "tool_use" }
        usage = data.fetch("usage", {})

        ProviderResponse.new(
          content: text.to_s.empty? ? nil : text,
          tool_calls: tool_blocks.map { |block|
            ToolCall.new(id: block["id"], name: block["name"], arguments: block["input"] || {})
          },
          usage: Usage.new(usage.fetch("input_tokens", 0), usage.fetch("output_tokens", 0)),
          finish_reason: data["stop_reason"],
          content_blocks: content_blocks,
          file_ids: Skills::AnthropicContent.extract_file_ids(content_blocks),
          assistant_raw_content: content_blocks
        )
      end

      def connection(beta_headers = [])
        headers = {
          "x-api-key" => @api_key,
          "anthropic-version" => API_VERSION,
          "Content-Type" => "application/json"
        }
        headers["anthropic-beta"] = beta_headers.join(",") if beta_headers&.any?

        Faraday.new(url: "https://api.anthropic.com/v1", headers: headers)
      end

      def split_system(messages)
        system = messages.select { |message| message.role == :system }.map(&:content).join("\n")
        conversation = messages.reject { |message| message.role == :system }
        [system.to_s.empty? ? nil : system, conversation]
      end

      def serialize(messages)
        messages.filter_map do |message|
          case message.role
          when :user
            {role: "user", content: message.content}
          when :assistant
            if message.raw_content
              {role: "assistant", content: message.raw_content}
            else
              blocks = []
              blocks << {type: "text", text: message.content} if message.content.present?
              message.tool_calls&.each do |tool_call|
                blocks << {type: "tool_use", id: tool_call.id, name: tool_call.name, input: tool_call.arguments}
              end
              {role: "assistant", content: blocks}
            end
          when :tool
            {role: "user", content: [{type: "tool_result", tool_use_id: message.tool_call_id, content: message.content}]}
          end
        end
      end

      def parse_error(response)
        JSON.parse(response.body).dig("error", "message") rescue response.body
      end
    end
  end
end
