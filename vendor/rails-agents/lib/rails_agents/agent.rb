# frozen_string_literal: true

require "fileutils"

module RailsAgents
  class Agent
    class << self
      attr_reader :provider_name, :model_name, :description_text, :tool_classes,
        :max_turns_config, :discover_tools_config

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@tool_classes, Array(tool_classes).dup)
        subclass.instance_variable_set(:@skill_declarations, Array(skill_declarations).dup)
        subclass.instance_variable_set(:@discover_tools_config, discover_tools_config)
      end

      def provider(value = nil)
        return @provider_name if value.nil?
        @provider_name = value.to_sym
      end

      def model(value = nil)
        return @model_name if value.nil?
        @model_name = value
      end

      def description(value = nil, &block)
        return @description_text if value.nil? && !block
        @description_text = block || value
      end

      def tools(*values)
        return @tool_classes || [] if values.empty?
        @tool_classes = values.flatten
      end

      def skills(*args, **kwargs)
        return skill_declarations if args.empty? && kwargs.empty?

        @skill_declarations ||= []
        args.each do |arg|
          if arg.is_a?(Hash)
            arg.each { |name, options| merge_skill(name, options) }
          else
            merge_skill(arg, kwargs)
          end
        end
        @skill_declarations
      end

      def skill_declarations
        @skill_declarations || []
      end

      def max_turns(value = nil)
        return @max_turns_config || Runner::DEFAULT_TURNS if value.nil?
        @max_turns_config = value
      end

      # When false, only declared tools and portable skill tools are available.
      # Useful when app/agents/tools contains tools for multiple agents.
      def discover_tools(value = nil)
        return @discover_tools_config.nil? ? true : @discover_tools_config if value.nil?
        @discover_tools_config = value
      end

      def resolved_provider
        provider_name || RailsAgents.config.default_provider
      end

      def resolved_model
        model_name || raise(ConfigurationError, "Add a model to #{name}. Example: model \"gpt-4o-mini\"")
      end

      def provider_client
        Providers.build(resolved_provider)
      end

      def skill_set
        @skill_set ||= SkillSet.new(declarations: skill_declarations, provider: resolved_provider).tap(&:validate!)
      end

      def tool_set
        discovered = discover_tools && defined?(Rails) ? ToolSet.from_directory : ToolSet.new
        portable = ToolSet.new(*skill_set.portable_tool_classes)
        declared = ToolSet.new(*tool_classes)
        declared.+(portable).+(discovered)
      end

      def render_instructions(context = {})
        text = description_text
        case text
        when Proc then text.call(context)
        when nil then raise ConfigurationError, "Add a description to #{name}. Example: description \"What this agent does\""
        else text.to_s
        end
      end

      def run(input = nil, save_files_to: nil, callbacks: {}, parse_json: false, **context)
        Runner.new(
          self,
          input: input.nil? ? context : input,
          context: context.merge(save_files_to:),
          callbacks: callbacks,
          parse_json: parse_json
        ).call
      end

      alias ask run
      alias call run

      private

      def merge_skill(name, options)
        key = name.to_s
        existing = skill_declarations.find { |declaration| declaration.key.to_s == key }
        merged_options = existing ? existing.options.merge(options) : options.dup

        if existing
          @skill_declarations[skill_declarations.index(existing)] = SkillDeclaration.new(key: existing.key, options: merged_options)
        else
          @skill_declarations << SkillDeclaration.new(key: name, options: merged_options)
        end
      end
    end
  end
end
