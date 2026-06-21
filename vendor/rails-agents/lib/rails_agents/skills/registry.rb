# frozen_string_literal: true

module RailsAgents
  module Skills
    class Registry
      ENTRIES = {
        web_search: Skill.new(
          name: :web_search,
          kind: Skill::SERVER,
          anthropic_tool: {type: "web_search_20260209", name: "web_search"},
          portable_tool: Portable::WebSearch
        ),
        web_fetch: Skill.new(
          name: :web_fetch,
          kind: Skill::SERVER,
          anthropic_tool: {type: "web_fetch_20260309", name: "web_fetch"},
          portable_tool: Portable::WebFetch
        ),
        code_execution: Skill.new(
          name: :code_execution,
          kind: Skill::SERVER,
          anthropic_tool: {type: "code_execution_20250825", name: "code_execution"}
        ),
        memory: Skill.new(
          name: :memory,
          kind: Skill::SERVER,
          anthropic_tool: {type: "memory_20250818", name: "memory"}
        ),
        pptx: Skill.new(
          name: :pptx,
          kind: Skill::ANTHROPIC_DOCUMENT,
          anthropic_skill: {type: "anthropic", skill_id: "pptx", version: "latest"},
          requires: [:code_execution]
        ),
        xlsx: Skill.new(
          name: :xlsx,
          kind: Skill::ANTHROPIC_DOCUMENT,
          anthropic_skill: {type: "anthropic", skill_id: "xlsx", version: "latest"},
          requires: [:code_execution]
        ),
        docx: Skill.new(
          name: :docx,
          kind: Skill::ANTHROPIC_DOCUMENT,
          anthropic_skill: {type: "anthropic", skill_id: "docx", version: "latest"},
          requires: [:code_execution]
        ),
        pdf: Skill.new(
          name: :pdf,
          kind: Skill::ANTHROPIC_DOCUMENT,
          anthropic_skill: {type: "anthropic", skill_id: "pdf", version: "latest"},
          requires: [:code_execution]
        )
      }.freeze

      ANTHROPIC_SKILL_IDS = %i[pptx xlsx docx pdf].freeze
      PORTABLE_SKILL_IDS = %i[web_search web_fetch].freeze

      def self.fetch(name)
        ENTRIES[name.to_sym]
      end

      def self.known?(name)
        name.to_s.start_with?("skill_") || ENTRIES.key?(name.to_sym)
      end
    end
  end
end
