require_relative "../../ui/ui"

module FastlaneCI
  # A helper module with functions specific to gathering user input used by
  # the wizard. All configuration data is memoized, so the wizard will ask the
  # user to input the data if they haven't already. After that, the data may be
  # used normally
  module ConfigurationInputHelpers
    #####################################################
    # @!group Configuration: configuration data
    #####################################################

    # An encryption key used to encrypt the CI user's API token
    #
    # @return [String]
    def encryption_key
      @encryption_key ||= begin
        UI.message("Please enter an encryption key:")
        UI.input("FASTLANE_CI_ENCRYPTION_KEY = ")
      end
    end

    # The email associated with the CI user account
    #
    # @return [String]
    def ci_user_email
      @ci_user_email ||= begin
        UI.message("Please enter your CI bot account email:")
        UI.input("FASTLANE_CI_USER = ")
      end
    end

    # The API token associated with the CI user account
    #
    # @return [String]
    def ci_user_api_token
      @ci_user_api_token ||= begin
        UI.message("Please enter your CI bot account API token:")
        UI.input("FASTLANE_CI_PASSWORD = ")
      end
    end

    # The email associated with the clone user account
    #
    # @return [String]
    def clone_user_email
      @clone_user_email ||= begin
        UI.message("Please enter your email for the initial clone account:")
        UI.input("FASTLANE_CI_INITIAL_CLONE_EMAIL = ")
      end
    end

    # The API token associated with the clone user account
    #
    # @return [String]
    def clone_user_api_token
      @clone_user_api_token ||= begin
        UI.message("Please enter your API token for the initial clone account:")
        UI.input("FASTLANE_CI_INITIAL_CLONE_API_TOKEN = ")
      end
    end

    # The git repo used for configuration in the form: `username/reponame`
    #
    # @return [String]
    def repo_shortform
      @repo_shortform ||= begin
        UI.message("Please enter the name for your private configuration repo:")
        UI.input("FASTLANE_CI_REPO_URL=https://github.com/ ")
      end
    end
  end
end
