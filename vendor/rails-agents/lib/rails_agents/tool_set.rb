# frozen_string_literal: true

module RailsAgents
  class ToolSet
    def initialize(*tools)
      @tools = tools.flatten.compact.map { |t| resolve(t) }
    end

    def self.from_directory(path = nil)
      path ||= defined?(Rails) ? Rails.root.join("app/agents/tools") : nil
      return new unless path && Dir.exist?(path)

      classes = Dir.glob("#{path}/**/*.rb").filter_map do |file|
        require_dependency file if defined?(Rails)
        const_name = file.delete_prefix("#{path}/").delete_suffix(".rb").camelize
        const_name.safe_constantize
      end
      new(*classes)
    end

    def self.use(*tools) = new(*tools)

    def resolve(klass)
      case klass
      when Class
        klass < Tool ? klass : klass
      when String, Symbol
        resolved = klass.to_s.camelize.constantize
        raise Error, "#{klass} is not a RailsAgents::Tool" unless resolved < Tool
        resolved
      else
        klass
      end
    end

    def definitions = @tools.map(&:definition)
    def find(name) = @tools.find { |t| t.tool_name == name.to_s }
    def execute(name, arguments)
      tool_class = find(name)
      raise Error, "Unknown tool: #{name}" unless tool_class
      tool_class.new.call(**arguments.transform_keys(&:to_sym))
    end

    def +(other) = self.class.new(*@tools, *other.instance_variable_get(:@tools))
  end
end
