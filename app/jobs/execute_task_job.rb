# frozen_string_literal: true

class ExecuteTaskJob < ApplicationJob
  queue_as :monitors

  retry_on StandardError, wait: :polynomially_longer, attempts: 3

  def perform(task_id, task_run_id = nil)
    task = Task.find(task_id)
    return unless task.status == "active"

    run = task_run_id ? task.task_runs.find_by(id: task_run_id) : nil
    Tasks::Execute.call(task: task, run: run)
  end
end
