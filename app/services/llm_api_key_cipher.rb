# frozen_string_literal: true

class LlmApiKeyCipher
  class << self
    def encrypt(value)
      encryptor.encrypt_and_sign(value)
    end

    def decrypt(value)
      return nil if value.blank?

      encryptor.decrypt_and_verify(value)
    rescue ActiveSupport::MessageEncryptor::InvalidMessage
      nil
    end

    private

    def encryptor
      @encryptor ||= ActiveSupport::MessageEncryptor.new(
        Rails.application.key_generator.generate_key("meerkat-llm-api-key", ActiveSupport::MessageEncryptor.key_len)
      )
    end
  end
end
