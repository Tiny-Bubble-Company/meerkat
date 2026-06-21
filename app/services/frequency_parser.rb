# frozen_string_literal: true

module FrequencyParser
  class Error < StandardError; end

  module_function

  def parse!(value)
    normalized = value.to_s.strip
    raise Error, "frequency is required" if normalized.empty?

    if normalized.match?(/\A\d+\z/)
      return normalized.to_i
    end

    if (cron = parse_cron(normalized))
      return cron_interval_seconds(cron)
    end

    parse_phrase(normalized)
  end

  def parse_cron(value)
    return value if value.match?(%r{\A[\d*,\-/\s]+\z})

    nil
  end

  def cron_interval_seconds(cron)
    fugit = Fugit.parse(cron)
    raise Error, "invalid cron expression: #{cron}" unless fugit

    next_time = fugit.next_time
    following = fugit.next_time(next_time)
    (following.to_f - next_time.to_f).round
  end

  def parse_phrase(value)
    case value.downcase
    when "hourly", "every hour" then 1.hour.to_i
    when "daily", "every day" then 1.day.to_i
    when "weekly", "every week" then 1.week.to_i
    when /\Aevery\s+(\d+)\s+minutes?\z/i then Regexp.last_match(1).to_i * 60
    when /\Aevery\s+(\d+)\s+hours?\z/i then Regexp.last_match(1).to_i * 3600
    when /\Aevery\s+(\d+)\s+days?\z/i then Regexp.last_match(1).to_i * 86_400
    else
      raise Error, "unsupported frequency: #{value}. Use seconds, cron, or phrases like 'every 30 minutes'"
    end
  end
end
