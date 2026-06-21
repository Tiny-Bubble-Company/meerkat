# frozen_string_literal: true

module Tasks
  class Destroy
    def self.call(task:, permanent: false)
      new(task:, permanent:).call
    end

    def initialize(task:, permanent: false)
      @task = task
      @permanent = permanent
    end

    def call
      if @permanent
        @task.destroy!
        return nil
      end

      @task.update!(status: "archived")

      Report.call(
        task: @task,
        event_type: "task_archived",
        payload: {
          task_id: @task.id,
          archived_at: Time.current.iso8601
        }
      )

      @task
    end
  end
end
