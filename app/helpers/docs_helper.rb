# frozen_string_literal: true

module DocsHelper
  DOCS_SECTIONS = {
    "api-keys" => { label: "API Keys", interactive: true },
    "llm-provider" => { label: "LLM Provider", interactive: true },
    "quickstart" => { label: "Quickstart", interactive: false },
    "authentication" => { label: "Authentication", interactive: false },
    "task-types" => { label: "Task types", interactive: false },
    "tasks" => { label: "Tasks API", interactive: false },
    "webhooks" => { label: "Webhooks", interactive: false },
    "reference" => { label: "OpenAPI", interactive: false }
  }.freeze

  def docs_sections
    DOCS_SECTIONS
  end

  def docs_nav_link(section, label = nil)
    label ||= DOCS_SECTIONS.dig(section, :label) || section.titleize
    active = @section == section
    link_to label, docs_section_path(section), class: "nav-link#{' active' if active}"
  end

  def docs_api_path(suffix)
    "#{api_base_url}#{suffix}"
  end
end
