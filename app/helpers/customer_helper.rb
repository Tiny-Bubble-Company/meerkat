# frozen_string_literal: true

module CustomerHelper
  def customer_display_name
    return unless customer_signed_in?

    current_customer.name.presence || current_customer.email.split("@").first
  end

  def customer_company_label
    return unless customer_signed_in?

    current_customer.company.presence
  end

  def customer_initials
    return unless customer_signed_in?

    if current_customer.name.present?
      parts = current_customer.name.strip.split(/\s+/)
      if parts.size >= 2
        "#{parts.first[0]}#{parts.last[0]}".upcase
      else
        parts.first[0, 2].upcase
      end
    else
      current_customer.email[0].upcase
    end
  end
end
