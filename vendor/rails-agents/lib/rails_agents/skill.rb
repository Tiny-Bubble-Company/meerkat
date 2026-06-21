# frozen_string_literal: true

module RailsAgents
  class Skill
    SERVER = :server
    PORTABLE = :portable
    ANTHROPIC_DOCUMENT = :anthropic_document

    attr_reader :name, :kind, :anthropic_tool, :anthropic_skill, :requires, :portable_tool

    def initialize(name:, kind:, anthropic_tool: nil, anthropic_skill: nil, requires: [], portable_tool: nil)
      @name = name.to_sym
      @kind = kind
      @anthropic_tool = anthropic_tool
      @anthropic_skill = anthropic_skill
      @requires = requires.map(&:to_sym)
      @portable_tool = portable_tool
    end

    def server? = kind == SERVER
    def portable? = kind == PORTABLE
    def anthropic_document? = kind == ANTHROPIC_DOCUMENT
  end
end
