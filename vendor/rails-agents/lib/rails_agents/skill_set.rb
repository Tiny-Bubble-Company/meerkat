# frozen_string_literal: true

module RailsAgents
  class SkillSet
    FILES_BETA = "files-api-2025-04-14"

    attr_reader :provider, :entries, :custom_skills, :declarations

    def initialize(declarations:, provider:)
      @provider = provider.to_sym
      @declarations = declarations
      @custom_skills = []
      @options_by_name = declarations.to_h { |declaration|
        key = declaration.custom? ? declaration.key.to_s : declaration.name.to_s
        [key, declaration.options]
      }
      @entries = expand(resolve)
    end

    def server_tool_names
      entries.select(&:server?).filter_map { |entry| entry.anthropic_tool&.dig(:name) }
    end

    def portable_tool_classes
      return [] unless use_portable?

      entries.filter_map(&:portable_tool)
    end

    def anthropic_document_skills?
      entries.any?(&:anthropic_document?) || custom_skills.any?
    end

    def anthropic_request
      return {} unless provider == :anthropic

      tools = entries.filter_map { |entry| anthropic_tool_for(entry) }
      skills = entries.filter_map { |entry| anthropic_skill_for(entry) } + custom_skills
      headers = anthropic_beta_headers(tools:, skills:)

      {
        server_tools: tools.uniq { |tool| tool[:name] },
        container: (skills.empty? ? nil : {skills: skills}),
        beta_headers: headers
      }
    end

    def validate!
      if custom_skills.any? && provider != :anthropic
        raise ConfigurationError, "Custom Anthropic skills require provider :anthropic"
      end

      declarations.each do |declaration|
        next if declaration.custom?
        next if Skills::Registry.fetch(declaration.name)

        raise ConfigurationError, "Unknown skill: #{declaration.key}. See RailsAgents::Skills::Registry::ENTRIES"
      end

      entries.each do |entry|
        next if provider == :anthropic
        next if entry.portable_tool

        raise ConfigurationError,
          "Skill :#{entry.name} requires provider :anthropic. " \
          "Portable skills: #{Skills::Registry::PORTABLE_SKILL_IDS.join(', ')}"
      end
    end

    private

    def use_portable?
      provider != :anthropic
    end

    def resolve
      declarations.filter_map do |declaration|
        if declaration.custom?
          @custom_skills << anthropic_custom_skill(declaration)
          next
        end

        Skills::Registry.fetch(declaration.name)
      end
    end

    def expand(resolved)
      expanded = resolved.dup
      resolved.each do |entry|
        entry.requires.each do |required|
          dependency = Skills::Registry.fetch(required)
          expanded << dependency unless expanded.any? { |existing| existing.name == dependency.name }
        end
      end
      expanded.uniq { |entry| entry.name }
    end

    def anthropic_tool_for(entry)
      return unless entry.anthropic_tool

      tool = entry.anthropic_tool.dup
      options = @options_by_name.fetch(entry.name.to_s, {})
      merge_tool_options!(tool, options)
      tool
    end

    def anthropic_skill_for(entry)
      return unless entry.anthropic_skill

      skill = entry.anthropic_skill.dup
      options = @options_by_name.fetch(entry.name.to_s, {})
      skill[:version] = options.fetch(:version, skill[:version] || "latest")
      skill
    end

    def anthropic_custom_skill(declaration)
      {
        type: "custom",
        skill_id: declaration.key.to_s,
        version: declaration.options.fetch(:version, "latest")
      }
    end

    def merge_tool_options!(tool, options)
      allowed = %i[max_uses allowed_domains blocked_domains user_location response_inclusion]
      options.each do |key, value|
        tool[key] = value if allowed.include?(key.to_sym)
      end
    end

    def anthropic_beta_headers(tools:, skills:)
      headers = []
      headers << "code-execution-2025-08-25" if skills.any? || tools.any? { |tool| tool[:name] == "code_execution" }
      headers << "skills-2025-10-02" if skills.any?
      headers << FILES_BETA if skills.any? || tools.any? { |tool| tool[:name] == "code_execution" }
      headers
    end
  end
end
