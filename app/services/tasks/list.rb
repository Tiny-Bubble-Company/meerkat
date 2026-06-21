# frozen_string_literal: true

module Tasks
  class List
    Result = Data.define(:records, :total, :limit, :offset)

    def self.call(**options)
      new(**options).call
    end

    def initialize(task_type: nil, status: nil, include_archived: false, limit: 50, offset: 0, customer: nil)
      @task_type = task_type
      @status = status
      @include_archived = include_archived
      @limit = [ [ limit.to_i, 1 ].max, 200 ].min
      @offset = [ offset.to_i, 0 ].max
      @customer = customer
    end

    def call
      scope = Task.order(created_at: :desc)
      scope = scope.where(customer: @customer) if @customer
      scope = scope.where.not(status: "archived") unless @include_archived
      scope = scope.where(task_type: @task_type) if @task_type.present?
      scope = scope.where(status: @status) if @status.present?

      total = scope.count
      records = scope.offset(@offset).limit(@limit)

      Result.new(records: records, total: total, limit: @limit, offset: @offset)
    end
  end
end
