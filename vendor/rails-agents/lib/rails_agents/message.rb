# frozen_string_literal: true

module RailsAgents
  Message = Data.define(:role, :content, :tool_calls, :tool_call_id, :raw_content) do
    def self.system(content) = new(role: :system, content:, tool_calls: nil, tool_call_id: nil, raw_content: nil)
    def self.user(content) = new(role: :user, content:, tool_calls: nil, tool_call_id: nil, raw_content: nil)
    def self.assistant(content, tool_calls: nil, raw_content: nil)
      new(role: :assistant, content:, tool_calls:, tool_call_id: nil, raw_content:)
    end
    def self.tool(content, tool_call_id:) = new(role: :tool, content:, tool_calls: nil, tool_call_id:, raw_content: nil)
  end

  ToolCall = Data.define(:id, :name, :arguments)
  Usage = Data.define(:input_tokens, :output_tokens) do
    def total = input_tokens + output_tokens
  end

  ProviderResponse = Data.define(
    :content,
    :tool_calls,
    :usage,
    :finish_reason,
    :content_blocks,
    :file_ids,
    :assistant_raw_content
  )
end
