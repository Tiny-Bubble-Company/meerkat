# frozen_string_literal: true

module OnboardingHelper
  ONBOARDING_STEPS = [
    { slug: "api-key", label: "API key" },
    { slug: "llm-provider", label: "LLM key" },
    { slug: "create-task", label: "Create task" },
    { slug: "run-task", label: "Run task" },
    { slug: "waiting", label: "First run" },
    { slug: "success", label: "Done" }
  ].freeze

  def onboarding_progress(step)
    current_index = ONBOARDING_STEPS.index { |item| item[:slug] == step } || 0

    content_tag(:ol, class: "onboarding-progress") do
      safe_join(ONBOARDING_STEPS.each_with_index.map do |item, index|
        state = if index < current_index
                  "done"
                elsif index == current_index
                  "current"
                else
                  "upcoming"
                end

        content_tag(:li, item[:label], class: "onboarding-step onboarding-step--#{state}")
      end)
    end
  end
end
