RailsAgents.configure do |config|
  config.openai_api_key = ENV["OPENAI_API_KEY"]
  config.anthropic_api_key = ENV["ANTHROPIC_API_KEY"]
  config.openrouter_api_key = ENV["OPENROUTER_API_KEY"]
  config.grok_api_key = ENV["XAI_API_KEY"]
end
