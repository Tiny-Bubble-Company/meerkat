# frozen_string_literal: true

module RailsAgents
  module Skills
    module AnthropicContent
      module_function

      def extract_text(blocks)
        Array(blocks).select { |block| block["type"] == "text" }.map { |block| block["text"] }.join("\n").strip
      end

      def extract_file_ids(blocks)
        ids = []
        walk(blocks) { |node| ids << node["file_id"] if node.is_a?(Hash) && !node["file_id"].to_s.empty? }
        ids.uniq
      end

      def walk(object)
        case object
        when Array
          object.each { |item| walk(item) { |node| yield node } }
        when Hash
          yield object
          object.each_value { |value| walk(value) { |node| yield node } }
        end
      end
    end
  end
end
