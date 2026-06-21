# frozen_string_literal: true

class DispatchDueTasksJob < ApplicationJob
  queue_as :scheduler

  def perform
    Task.due.find_each do |task|
      task.with_lock do
        next unless task.next_run_at <= Time.current
        next if task.task_runs.exists?(status: "running")

        task.update!(next_run_at: Time.current + task.frequency_seconds.seconds)
        ExecuteTaskJob.perform_later(task.id)
      end
    end
  end
end
