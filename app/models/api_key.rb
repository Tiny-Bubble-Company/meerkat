# frozen_string_literal: true

class ApiKey < ApplicationRecord
  TOKEN_PREFIX = "mk_"

  belongs_to :customer

  validates :name, presence: true
  validates :token_digest, presence: true, uniqueness: true
  validates :token_prefix, presence: true

  scope :active, -> { where(revoked_at: nil) }

  def self.generate!(customer:, name: "Default")
    raw_token = "#{TOKEN_PREFIX}#{SecureRandom.urlsafe_base64(32)}"
    api_key = customer.api_keys.create!(
      name: name,
      token_digest: digest(raw_token),
      token_prefix: raw_token[0, 12]
    )
    [ api_key, raw_token ]
  end

  def self.authenticate(raw_token)
    return nil if raw_token.blank?

    normalized = raw_token.to_s.strip
    return nil unless normalized.start_with?(TOKEN_PREFIX)

    api_key = active.find_by(token_digest: digest(normalized))
    return nil unless api_key

    api_key.touch_last_used!
    api_key
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  def revoked?
    revoked_at.present?
  end

  def touch_last_used!
    update_column(:last_used_at, Time.current)
  end
end
