# frozen_string_literal: true

module RailsAgents
  Result = Data.define(:output, :data, :files, :messages, :usage, :success, :error, :content_blocks) do
    def self.ok(output:, files: [], data: nil, messages: [], usage: Usage.new(0, 0), content_blocks: nil)
      new(output:, data:, files:, messages:, usage:, success: true, error: nil, content_blocks:)
    end

    def self.fail(error:, messages: [], usage: Usage.new(0, 0), content_blocks: nil)
      new(output: nil, data: nil, files: [], messages:, usage:, success: false, error:, content_blocks:)
    end
  end
end
