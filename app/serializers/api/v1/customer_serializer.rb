# frozen_string_literal: true

module Api
  module V1
    module CustomerSerializer
      module_function

      def render(customer)
        {
          id: customer.id,
          email: customer.email,
          name: customer.name,
          company: customer.company,
          created_at: customer.created_at
        }
      end
    end
  end
end
