# frozen_string_literal: true

module OnboardingWebhookToken
  PURPOSE = "onboarding_webhook_inbox"

  module_function

  def generate(customer_id)
    Rails.application.message_verifier(PURPOSE).generate(customer_id, expires_in: 7.days)
  end

  def verify(token)
    return nil if token.blank?

    Rails.application.message_verifier(PURPOSE).verify(token)
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    nil
  end
end
