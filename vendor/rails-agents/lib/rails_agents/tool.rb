# frozen_string_literal: true

require "active_support/core_ext/string/inflections"

module RailsAgents
  class Tool
    class << self
      attr_reader :description_text, :parameters

      def inherited(subclass)
        super
        subclass.instance_variable_set(:@parameters, (parameters || {}).dup)
      end

      def description(text = nil)
        return @description_text if text.nil?
        @description_text = text
      end

      def param(name, type, required: true, description: nil)
        @parameters ||= {}
        @parameters[name.to_sym] = {type: type.to_sym, required:, description:}
      end

      def tool_name
        name.split("::").last.gsub(/Tool$/, "").underscore
      end

      def definition
        {
          name: tool_name,
          description: description_text,
          parameters: {
            type: "object",
            properties: parameters.transform_values { |p|
              {type: p[:type].to_s, description: p[:description]}.compact
            },
            required: parameters.select { |_, p| p[:required] }.keys.map(&:to_s)
          }
        }
      end
    end

    def call(**kwargs)
      raise NotImplementedError
    end
  end
end
