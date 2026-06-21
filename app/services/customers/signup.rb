# frozen_string_literal: true

module Customers
  class Signup
    class Error < StandardError; end

    def self.call(**attributes)
      new(**attributes).call
    end

    def initialize(email:, name: nil, company: nil)
      @email = email
      @name = name
      @company = company
    end

    def call
      customer = Customer.create!(email: @email, name: @name, company: @company)
      _api_key, raw_token = ApiKey.generate!(customer: customer)

      { customer: customer, api_key: raw_token }
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.join(", ")
    end
  end
end
