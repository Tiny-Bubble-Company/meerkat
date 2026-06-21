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
