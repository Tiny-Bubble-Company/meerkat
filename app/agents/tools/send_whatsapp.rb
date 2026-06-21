# frozen_string_literal: true

module Tools
  class SendWhatsapp < RailsAgents::Tool
    description "Send a WhatsApp message when the task description asks for WhatsApp delivery"
    param :to, :string, description: "Recipient phone number in E.164 format, e.g. +14155551212"
    param :message, :string, description: "Message body"

    def call(to:, message:)
      provider = ENV["MEERKAT_WHATSAPP_PROVIDER"]

      unless provider.present?
        return {
          delivered: false,
          skipped: true,
          reason: "WhatsApp provider not configured. Set MEERKAT_WHATSAPP_PROVIDER."
        }
      end

      case provider
      when "twilio"
        send_via_twilio(to:, message:)
      else
        { delivered: false, error: "Unknown WhatsApp provider: #{provider}" }
      end
    end

    private

    def send_via_twilio(to:, message:)
      account_sid = ENV.fetch("TWILIO_ACCOUNT_SID")
      auth_token = ENV.fetch("TWILIO_AUTH_TOKEN")
      from = ENV.fetch("TWILIO_WHATSAPP_FROM")

      response = Faraday.post("https://api.twilio.com/2010-04-01/Accounts/#{account_sid}/Messages.json") do |req|
        req.headers["Content-Type"] = "application/x-www-form-urlencoded"
        req.basic_auth(account_sid, auth_token)
        req.body = URI.encode_www_form(From: from, To: "whatsapp:#{to}", Body: message)
      end

      {
        delivered: response.success?,
        status: response.status,
        provider: "twilio"
      }
    rescue StandardError => e
      { delivered: false, error: e.message, provider: "twilio" }
    end
  end
end
