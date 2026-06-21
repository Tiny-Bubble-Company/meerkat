# frozen_string_literal: true

class OpsHostConstraint
  OPS_HOST = "ops.meerkatagents.com"

  def self.matches?(request)
    request.host == OPS_HOST ||
      (Rails.env.development? && request.host.in?(%w[localhost 127.0.0.1]))
  end
end
