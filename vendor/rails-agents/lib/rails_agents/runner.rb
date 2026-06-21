# frozen_string_literal: true

module RailsAgents
  class Runner
    DEFAULT_TURNS = 12

    def initialize(agent_class, input:, context: {}, callbacks: {}, parse_json: false, provider: nil, model: nil)
      @agent = agent_class
      @input = input
      @context = context
      @callbacks = callbacks
      @parse_json = parse_json
      @skills = agent_class.skill_set
      @tools = agent_class.tool_set
      @provider = provider || agent_class.provider_client
      @model_override = model
      @server_tool_names = @skills.server_tool_names
      @save_files_to = context[:save_files_to]
      @messages = []
    end

    def call
      emit(:start, agent: @agent.name, input: @input, context: @context)

      @messages << Message.system(@agent.render_instructions(@context))
      @messages << Message.user(format_input(@input))

      turns = 0
      total_usage = Usage.new(0, 0)
      last_response = nil

      loop do
        turns += 1
        raise Error, "Turn limit reached" if turns > @agent.max_turns

        emit(:turn_start, turn: turns)

        response = @provider.chat(
          messages: @messages,
          client_tools: @tools.definitions,
          skills: @skills,
          model: @model_override || @agent.resolved_model
        )
        last_response = response

        total_usage = Usage.new(
          total_usage.input_tokens + response.usage.input_tokens,
          total_usage.output_tokens + response.usage.output_tokens
        )

        emit(:turn_complete, turn: turns, usage: response.usage, tool_calls: response.tool_calls.map(&:name))

        client_tool_calls = response.tool_calls.reject { |tool_call| @server_tool_names.include?(tool_call.name) }

        if client_tool_calls.any?
          @messages << Message.assistant(
            response.content,
            tool_calls: client_tool_calls,
            raw_content: response.assistant_raw_content
          )
          client_tool_calls.each do |tool_call|
            emit(:tool_start, name: tool_call.name, arguments: tool_call.arguments)
            result = @tools.execute(tool_call.name, tool_call.arguments)
            emit(:tool_finish, name: tool_call.name, result: result)
            @messages << Message.tool(result.to_json, tool_call_id: tool_call.id)
          end
          next
        end

        files = download_files(response.file_ids)
        data = parse_structured_output(response.content)
        result = Result.ok(
          output: response.content,
          data: data,
          files: files,
          messages: @messages,
          usage: total_usage,
          content_blocks: response.content_blocks
        )
        emit(:finish, result: result)
        return result
      end
    rescue StandardError => e
      result = Result.fail(error: e.message, messages: @messages, usage: Usage.new(0, 0))
      emit(:error, error: e.message, result: result)
      result
    end

    private

    def emit(event, payload = {})
      @callbacks[event]&.call(payload)
      instrument(event, payload)
    end

    def instrument(event, payload)
      return unless defined?(ActiveSupport::Notifications)

      ActiveSupport::Notifications.instrument(
        "rails_agents.#{event}",
        payload.merge(agent: @agent.name)
      )
    end

    def parse_structured_output(content)
      return nil unless @parse_json
      return nil if content.nil? || content.strip.empty?

      JSON.parse(content)
    rescue JSON::ParserError
      extract_json_object(content)
    end

    def extract_json_object(content)
      match = content.match(/\{.*\}/m)
      return nil unless match

      JSON.parse(match[0])
    rescue JSON::ParserError
      nil
    end

    def format_input(input)
      case input
      when String then input
      when Hash then input.to_json
      else input.to_s
      end
    end

    def download_files(file_ids)
      return [] if file_ids.empty?
      return [] unless @agent.resolved_provider == :anthropic
      return [] unless RailsAgents.config.anthropic_auto_download_files
      return [] unless @provider.respond_to?(:files)

      directory = @save_files_to || RailsAgents.config.anthropic_files_directory!
      FileUtils.mkdir_p(directory)

      file_ids.map do |file_id|
        generated = @provider.files.download(file_id)
        generated.save(directory)
      end
    end
  end
end
