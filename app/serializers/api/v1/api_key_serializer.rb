# frozen_string_literal: true

module Api
  module V1
    module ApiKeySerializer
      module_function

      def render(api_key)
        {
          id: api_key.id,
          name: api_key.name,
          token_prefix: api_key.token_prefix,
          last_used_at: api_key.last_used_at,
          revoked_at: api_key.revoked_at,
          created_at: api_key.created_at
        }
      end
    end
  end
end
