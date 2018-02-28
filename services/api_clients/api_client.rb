# frozen_string_literal: true

module FastlaneCI
  # Injectable ApiClient module exposing APIs for the CI user, and clone users
  #
  # @abstract
  module ApiClient
    # Returns an API client object with the CI user credentials
    #
    # @abstract
    def ci_user_api
      not_implemented(__method__)
    end

    # Returns an API client object with the clone user credentials
    #
    # @abstract
    def clone_user_api
      not_implemented(__method__)
    end
  end
end
