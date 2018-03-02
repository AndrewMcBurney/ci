require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"
require_relative "../../services/api_clients/github_client"

module FastlaneCI
  #
  # A CRUD controller to manage configuration data for FastlaneCI. Walks the
  # user through configuration should they not have the proper metadata required
  # to run the server
  #
  class ConfigurationController < AuthenticatedControllerBase
    include GitHubClient

    HOME = "/configuration"

    # Enum for status of POST operations
    STATUS = { success: :success, error: :error }

    #####################################################
    # @!group GET: HTTP GET verbs
    #####################################################

    get HOME do
      locals = { title: "Configuration", variables: {} }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/keys" do
      locals = { title: "Keys", variables: {} }
      erb(:keys, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/users" do
      locals = { title: "Users", variables: {} }
      erb(:users, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/projects" do
      locals = { title: "Projects", variables: {} }
      erb(:projects, locals: locals, layout: FastlaneCI.default_layout)
    end

    #####################################################
    # @!group POST Keys: POST verbs - .keys
    #####################################################

    post "#{HOME}/keys" do
      status =
        if valid_locals?(params, keys_locals)
          Services.file_writer_service.write_keys_file!(locals: params)
          Launch.load_dot_env
          create_private_remote_configuration_repo
          STATUS[:success]
        else
          STATUS[:error]
        end

      locals = { title: "Keys", variables: { status: status } }
      erb(:keys, locals: locals, layout: FastlaneCI.default_layout)
    end

    #####################################################
    # @!group POST Users: POST verbs - users.json
    #####################################################

    post "#{HOME}/users/create" do
      status =
        if valid_locals?(params, users_locals)
          Services.file_writer_service.write_users_file!(locals: params)
          STATUS[:success]
        else
          erb(:users, locals: locals, layout: FastlaneCI.default_layout)
          STATUS[:error]
        end

      locals = { title: "Users", variables: { status: status } }
      erb(:keys, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Updates a user existing in the configuration repository `users.json`
    post "#{HOME}/users/update" do
    end

    # Removes a user from the configuration git repo `users.json`, but
    # does not actually delete the user
    post "#{HOME}/users/delete" do
    end

    #####################################################
    # @!group POST Keys: POST verbs - projects.json
    #####################################################

    post "#{HOME}/projects/create" do
      status =
        if valid_locals?(params, users_locals)
          Services.file_writer_service.write_projects_file!(locals: params)
          STATUS[:success]
        else
          STATUS[:error]
        end

      locals = { title: "Projects", variables: { status: status } }
      erb(:projects, locals: locals, layout: FastlaneCI.default_layout)
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

    # Empty project object for new user form
    #
    # @return [Project]
    def new_project
      @new_user ||= Project.new(repo_config: GitRepoConfig.new)
    end

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # Validates all the required keys are present, and that no values are nil
    #
    # @param  [Hash]       actuals
    # @param  [Set[Symbol] expected_keys
    # @return [Boolean]
    def valid_locals?(actuals, expected_keys)
      expected_keys.subset?(actuals.keys.to_set) && actuals.values.none?(&:nil?)
    end

    # @return [Set[String]]
    def keys_locals
      Set.new(
        %w(encryption_key ci_user_email ci_user_api_token repo_shortform
           clone_user_email clone_user_api_token)
      )
    end

    # @return [Set[Symbol]]
    def users_locals
      Set.new(%w(ci_user_email ci_user_api_token))
    end

    # @return [Set[Symbol]]
    def project_locals
      Set.new(%w(project_full_name))
    end

    #####################################################
    # @!group Helpers: GitHub helpers
    # TODO: figure out where best to put this logic
    #####################################################

    # Creates a remote repository
    #
    # @param [String] repo_shortform
    def create_private_remote_configuration_repo(repo_shortform)
      repo_name = repo_shortform.split("/")[1]
      clone_user_api.create_repository(repo_name, private: true)
    end

    # Commits the most recent changes and pushes them to the new repo
    def commit_and_push_changes!
      Services.configuration_git_repo.commit_changes!
      Services.configuration_git_repo.push
    end

    #####################################################
    # @!group Other Helpers: unrelated helpers
    #####################################################

    # TODO: implement me
    def first_time_user?
      true
    end
  end
end
