require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"
require_relative "../../services/api_clients/github_client"

# TODO: form validations, error handling. Potentially metaprogram some of this
# to reduce duplication
module FastlaneCI
  #
  # A CRUD controller to manage configuration data for FastlaneCI. Walks the
  # user through configuration should they not have the proper metadata required
  # to run the server
  #
  class ConfigurationController < ControllerBase
    include GitHubClient

    HOME = "/configuration"

    # Enum for status of POST operations
    STATUS = { success: :success, error: :error }

    #####################################################
    # @!group GET: HTTP GET verbs
    #####################################################

    get HOME do
      locals = {
        title: "Configuration",
        variables: { first_time_user: false }
      }
      erb(:index, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/keys" do
      locals = {
        title: "Keys",
        variables: { keys: keys }
      }
      erb(:keys, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/users" do
      locals = {
        title: "Users",
        variables: { users: users }
      }
      erb(:users, locals: locals, layout: FastlaneCI.default_layout)
    end

    get "#{HOME}/projects" do
      locals = {
        title: "Projects",
        variables: { projects: projects }
      }
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
          STATUS[:success]
        else
          STATUS[:error]
        end

      locals = { title: "Keys", variables: { keys: keys, status: status } }
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

      locals = { title: "Users", variables: { users: users, status: status } }
      erb(:keys, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Updates a user existing in the configuration repository `users.json`
    post "#{HOME}/users/update/:id" do
    end

    # Removes a user from the configuration git repo `users.json`, but
    # does not actually delete the user
    post "#{HOME}/users/delete/:id" do
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

      locals = { title: "Projects", variables: { projects: projects, status: status } }
      erb(:projects, locals: locals, layout: FastlaneCI.default_layout)
    end

    # Updates a project existing in the configuration repository `projects.json`
    post "#{HOME}/projects/update/:id" do
    end

    # Removes a project from the configuration git repo `projects.json`, but
    # does not actually delete the project repository
    post "#{HOME}/projects/delete/:id" do
      # TODO: consider using projects_controller delete action instead? - probably better
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

    def users
      nil
    end

    def projects
      nil
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
  end
end
