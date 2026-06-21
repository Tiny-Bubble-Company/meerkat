# frozen_string_literal: true

module DeployHelper
  def github_repo_url
    ENV.fetch("MEERKAT_GITHUB_REPO", "https://github.com/Tiny-Bubble-Company/meerkat")
  end

  def meerkat_website_url
    ENV.fetch("MEERKAT_WEBSITE_URL", "https://meerkatagents.com")
  end

  def meerkat_cloud_url
    ENV.fetch("MEERKAT_CLOUD_URL", "https://cloud.meerkatagents.com")
  end

  def deploy_to_render_url
    "https://render.com/deploy?repo=#{CGI.escape(github_repo_url)}"
  end

  def deploy_to_fly_url
    "https://fly.io/launch?source=#{CGI.escape(github_repo_url)}"
  end
end
