# frozen_string_literal: true

module Tasks
  class Find
    def self.call(id:)
      Task.find(id)
    end
  end
end
