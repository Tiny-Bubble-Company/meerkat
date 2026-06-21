# frozen_string_literal: true

module RailsAgents
  SkillDeclaration = Data.define(:key, :options) do
    def custom? = key.to_s.start_with?("skill_")
    def name = custom? ? key.to_s : key.to_sym
  end
end
