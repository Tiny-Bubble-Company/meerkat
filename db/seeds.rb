# frozen_string_literal: true

if RailsAgents.config.api_key_for(RailsAgents.config.default_provider).present?
  recurring = Tasks::Create.call(
    task_type: "recurring",
    description: "Monitor the courier tracking page and report when delivery status or location changes.",
    input_params: {
      courier_tracking_link: "https://www.fedex.com/fedextrack/?trknbr=123456789012"
    },
    frequency: "every 2 hours",
    output_webhook: ENV.fetch("MEERKAT_DEMO_WEBHOOK", "https://example.com/webhooks/meerkat"),
    metadata: { use_case: "courier_informer" },
    run_immediately: false
  )

  one_off = Tasks::Create.call(
    task_type: "one_off",
    description: "Fetch courier status once and report findings.",
    input_params: {
      courier_tracking_link: "https://www.fedex.com/fedextrack/?trknbr=123456789012"
    },
    output_webhook: ENV.fetch("MEERKAT_DEMO_WEBHOOK", "https://example.com/webhooks/meerkat"),
    metadata: { use_case: "courier_informer_one_off" },
    run_immediately: false
  )

  puts "Created recurring task ##{recurring.id} and one_off task ##{one_off.id}"
else
  puts "Skipping demo seeds — set ANTHROPIC_API_KEY to create live tasks"
end

ops_email = ENV.fetch("OPS_ADMIN_EMAIL", "ops@meerkatagents.com")
ops_password = ENV["OPS_ADMIN_PASSWORD"].presence
ops_password ||= "changeme123!" unless Rails.env.production?

admin = AdminUser.find_by(email: ops_email)
if admin.nil?
  if ops_password.blank?
    puts "Skipping ops admin seed — set OPS_ADMIN_PASSWORD"
  else
    AdminUser.create!(email: ops_email, name: "Ops Admin", password: ops_password)
    puts "Created ops admin #{ops_email}"
  end
elsif ENV["OPS_ADMIN_PASSWORD"].present?
  admin.update!(password: ops_password)
  puts "Updated ops admin password for #{ops_email}"
else
  puts "Ops admin #{ops_email} already exists"
end
