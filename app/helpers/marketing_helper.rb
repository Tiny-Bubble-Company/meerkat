# frozen_string_literal: true

module MarketingHelper
  USE_CASES = [
    {
      label: "Package tracking",
      path: :package_tracking_path,
      description: "Monitor shipments and delivery events in real time"
    },
    {
      label: "Site monitoring",
      path: :website_monitoring_path,
      description: "Uptime and change detection for any URL"
    },
    {
      label: "Agent webhooks",
      path: :agent_webhooks_path,
      description: "Trigger AI agents from observed events"
    }
  ].freeze

  def marketing_signup_path
    if marketing_site_host?
      return cloud_app_url("/signup") unless customer_signed_in?

      if current_customer.onboarding_completed?
        return cloud_app_url("/docs/api-keys")
      end

      step = session[:onboarding_step].presence || "api-key"
      return cloud_app_url("/onboarding/#{step}")
    end

    return signup_path unless customer_signed_in?

    if current_customer.onboarding_completed?
      docs_section_path("api-keys")
    else
      onboarding_step_path(session[:onboarding_step].presence || "api-key")
    end
  end

  def brand_home_url
    marketing_site_host? ? root_path : meerkat_website_url
  end

  def marketing_signup_link_options(**html_options)
    if marketing_site_host?
      html_options[:target] = "_blank"
      html_options[:rel] = "noopener noreferrer"
    end
    html_options
  end

  def marketing_docs_path
    marketing_site_host? ? cloud_app_url("/docs") : docs_path
  end

  def marketing_docs_section_path(section)
    marketing_site_host? ? cloud_app_url("/docs/#{section}") : docs_section_path(section)
  end

  def marketing_signup_label
    return "Sign up free" unless customer_signed_in?

    current_customer.onboarding_completed? ? "API keys →" : "Continue setup →"
  end

  def marketing_nav_cta_label
    customer_signed_in? ? marketing_signup_label : "Sign up →"
  end

  def github_getting_started_anchor
    "#{github_repo_url}#getting-started--docker-recommended"
  end

  def github_issues_url
    "#{github_repo_url}/issues"
  end

  def github_releases_url
    "#{github_repo_url}/releases"
  end

  def marketing_canonical_url(path = request.path)
    "#{meerkat_website_url.chomp("/")}#{path}"
  end

  def faq_json_ld(faqs)
    {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => faqs.map do |faq|
        {
          "@type" => "Question",
          "name" => faq[:q],
          "acceptedAnswer" => { "@type" => "Answer", "text" => faq[:a] }
        }
      end
    }.to_json
  end
end
