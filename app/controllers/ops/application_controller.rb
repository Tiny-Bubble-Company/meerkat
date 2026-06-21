# frozen_string_literal: true

module Ops
  class ApplicationController < ::ApplicationController
    layout "ops"

    before_action :require_admin!

    private

    def paginate(relation)
      page = [ params.fetch(:page, 1).to_i, 1 ].max
      per = [ [ params.fetch(:per, 50).to_i, 1 ].max, 100 ].min
      records = relation.limit(per).offset((page - 1) * per)
      total = relation.reorder(nil).count
      [ records, page, per, total ]
    end
  end
end
