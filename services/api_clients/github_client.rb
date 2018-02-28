# frozen_string_literal: true

require_relative "./api_client"

module FastlaneCI
  # An injectable module for easy access to the GitHub API
  module GitHubClient
    extend ApiClient

    # Returns an GitHub API client object with the CI user credentials
    #
    # @return [Octokit::Client]
    def ci_user_api
      @api ||= Octokit::Client.new(
        access_token: ci_user_github_token,
        api_endpoint: github_api_endpoint
      )
    end

    # Returns an GitHub API client object with the clone user credentials
    #
    # @return [Octokit::Client]
    def clone_user_api
      @oauth_client_api ||= Octokit::Client.new(
        access_token: clone_user_github_token,
        api_endpoint: github_api_endpoint
      )
    end

    private

    # @return [String]
    def ci_user_github_token
      ENV["FASTLANE_CI_PASSWORD"]
    end

    # @return [String]
    def clone_user_github_token
      ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"]
    end

    # @return [String]
    def github_api_endpoint
      "https://api.github.com/"
    end
  end
end
