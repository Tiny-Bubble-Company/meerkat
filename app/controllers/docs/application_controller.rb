# frozen_string_literal: true

module Docs
  class ApplicationController < ::ApplicationController
    layout "docs"

    before_action :require_onboarding_complete!
    before_action :require_customer!

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
