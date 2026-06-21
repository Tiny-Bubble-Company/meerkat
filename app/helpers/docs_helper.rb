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

  TASKS_API_INDEX = [
    { id: "the-task-object", label: "The Task object" },
    { id: "list-tasks", label: "List tasks" },
    { id: "create-task", label: "Create a task" },
    { id: "retrieve-task", label: "Retrieve a task" },
    { id: "update-task", label: "Update a task" },
    { id: "replace-task", label: "Replace a task" },
    { id: "delete-task", label: "Delete a task" },
    { id: "run-task", label: "Run a task" },
    { id: "pause-task", label: "Pause a task" },
    { id: "resume-task", label: "Resume a task" },
    { id: "list-runs", label: "List runs" },
    { id: "list-events", label: "List events" }
  ].freeze

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
