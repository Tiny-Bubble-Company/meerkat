# frozen_string_literal: true

# Derive sibling database URLs from DATABASE_URL when deploying to PaaS platforms
# (Render, Fly.io) that only provide a single Postgres connection string.
db_url = ENV["DATABASE_URL"]
return if db_url.nil? || db_url.empty?

require "uri"

SIBLING_DATABASES = {
  "QUEUE_DATABASE_URL" => "_queue",
  "CACHE_DATABASE_URL" => "_cache",
  "CABLE_DATABASE_URL" => "_cable"
}.freeze

uri = URI.parse(ENV["DATABASE_URL"])
base_name = uri.path.delete_prefix("/").sub(/_(queue|cache|cable)\z/, "")

SIBLING_DATABASES.each do |env_key, suffix|
  existing = ENV[env_key]
  next if existing && !existing.empty?

  sibling = uri.dup
  sibling.path = "/#{base_name}#{suffix}"
  ENV[env_key] = sibling.to_s
end
