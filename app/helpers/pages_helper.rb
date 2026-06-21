# frozen_string_literal: true

module PagesHelper
  def api_base_url
    "#{request.base_url}/api/v1"
  end
end
