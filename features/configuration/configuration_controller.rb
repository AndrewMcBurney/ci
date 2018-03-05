require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  #
  # A CRUD controller to manage configuration data for FastlaneCI. Walks the
  # user through configuration should they not have the proper metadata required
  # to run the server
  #
  class ConfigurationController < AuthenticatedControllerBase
    HOME = "/configuration"

    get HOME do
      locals = { title: "Configuration", variables: {} }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    # When the `/keys` form is submitted:
    #
    # 1) Validate the data passed in
    #
    # 2) If the data is valid:
    #
    #    i.   write the environment variables file
    #    ii.  load the new environment variables
    #    iii. create the private configuration git repo remotely
    #    iv.  clone the configuration repo
    #
    # 3) If the data is not valid, display an error message
    #
    post "#{HOME}/keys" do
      status =
        if valid_params?(params, keys_params)
          Services.file_writer_service.write_keys_file!(locals: params)
          Services.environment_variable_service.reload_dot_env!
          Services.github_service.create_private_remote_configuration_repo
          Services.config_service.trigger_initial_ci_setup
          STATUS[:success]
        else
          STATUS[:error]
        end

      locals = { title: "Keys", variables: { status: status } }
      erb(:keys, locals: locals, layout: FastlaneCI.default_layout)
    end

    private

    #####################################################
    # @!group Data: View-specific data
    #####################################################

    # @return [Hash]
    def keys
      {
        encryption_key: ENV["FASTLANE_CI_ENCRYPTION_KEY"],
        ci_user_email: ENV["FASTLANE_CI_USER"],
        ci_user_api_token: ENV["FASTLANE_CI_PASSWORD"],
        repo_shortform: ENV["FASTLANE_CI_REPO_URL"],
        clone_user_email: ENV["FASTLANE_CI_INITIAL_CLONE_EMAIL"],
        clone_user_api_token: ENV["FASTLANE_CI_INITIAL_CLONE_API_TOKEN"]
      }
    end

    # @return [Array[User]]
    def users
      Services.user_service.user_data_source.users
    end

    # Empty user object for new user form
    #
    # @return [User]
    def new_user
      @new_user ||= User.new(provider_credentials: [GitHubProviderCredential.new])
    end

    # @return [Array[Project]]
    def projects
      Services.project_service.project_data_source.projects
    end

    # Empty project object for new project form
    #
    # @return [Project]
    def new_project
      @new_project ||= Project.new(repo_config: GitRepoConfig.new)
    end

    # Empty project object for new project form
    #
    # @return [Project]
    def new_credential
      @new_credential ||= GitHubProviderCredential.new
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[String]]
    def keys_params
      Set.new(
        %w(encryption_key ci_user_email ci_user_api_token repo_shortform
           clone_user_email clone_user_api_token)
      )
    end

    #####################################################
    # @!group Helpers: Random helper functions
    #####################################################

    # @return [Boolean]
    def first_time_user?
      Services.configuration_git_repo.first_time_user?
    end
  end
end
