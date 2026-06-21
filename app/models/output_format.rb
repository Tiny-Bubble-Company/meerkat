# frozen_string_literal: true

module OutputFormat
  DEFAULT = "default"
  PRESETS = %w[default compact flat findings_only minimal].freeze
  MAX_CUSTOM_LENGTH = 500

  module_function

  def preset?(value)
    value.present? && PRESETS.include?(value.to_s)
  end

  def custom_instruction?(value)
    value.present? && !preset?(value)
  end

  def normalize(value)
    value.presence
  end

  def effective(value)
    normalize(value) || DEFAULT
  end

  def validate!(value)
    return if value.blank?
    return if preset?(value)
    return if value.to_s.length <= MAX_CUSTOM_LENGTH

    raise ArgumentError, "output_format custom instruction must be #{MAX_CUSTOM_LENGTH} characters or fewer"
  end
end
