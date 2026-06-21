# frozen_string_literal: true

class Customer < ApplicationRecord
  LLM_PROVIDERS = Customers::SaveLlmCredential::PROVIDERS
  DEFAULT_LLM_MODELS = Customers::SaveLlmCredential::DEFAULT_MODELS

  has_many :api_keys, dependent: :destroy
  has_many :tasks, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :llm_provider, inclusion: { in: LLM_PROVIDERS }, allow_nil: true

  normalizes :email, with: ->(email) { email.strip.downcase }

  def onboarding_completed?
    onboarding_completed_at.present?
  end

  def complete_onboarding!
    update!(onboarding_completed_at: Time.current)
  end

  def llm_configured?
    llm_provider.present? && llm_api_key_ciphertext.present?
  end

  def resolved_llm_model
    llm_model.presence || DEFAULT_LLM_MODELS.fetch(llm_provider.to_s, TaskExecutor.model_name)
  end

  def llm_provider_label
    case llm_provider
    when "openrouter" then "OpenRouter"
    when "grok" then "Grok (xAI)"
    else llm_provider&.titleize
    end
  end

  def llm_api_key=(plain)
    self.llm_api_key_ciphertext = plain.present? ? LlmApiKeyCipher.encrypt(plain) : nil
  end

  def llm_api_key
    LlmApiKeyCipher.decrypt(llm_api_key_ciphertext)
  end

  def llm_key_hint
    return nil unless llm_api_key.present?

    key = llm_api_key
    "#{key.first(7)}…#{key.last(4)}"
  end
end
