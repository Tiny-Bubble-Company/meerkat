# frozen_string_literal: true

module OnboardingHelper
  def onboarding_test_webhook_url(customer = current_customer)
    token = OnboardingWebhookToken.generate(customer.id)
    "#{meerkat_cloud_url.chomp('/')}/onboarding/inbox?token=#{CGI.escape(token)}"
  end

  def onboarding_task_sample_payload
    {
      task_type: "one_off",
      description: "Fetch the page title from a Meerkat website",
      input_params: { url: "https://meerkatagents.com/" }
    }
  end
end
