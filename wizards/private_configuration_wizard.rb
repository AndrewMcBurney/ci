# rubocop:disable Layout/EmptyLinesAroundArguments

require_relative "./wizard"
require_relative "./helpers/configuration_wizard_helpers"

require_relative "../ui/ui"
require_relative "../services/api_clients/github_client"
require_relative "../services/file_writers/keys_writer"
require_relative "../services/file_writers/users_writer"
require_relative "../services/file_writers/projects_writer"

module FastlaneCI
  #
  # A class to walk a first-time user through creating a private configuration
  # repository:
  #
  # 1) Prints a welcome message to the user and notifies them that they're
  #    running the server for the first time
  #
  # 2) Prints information about the environment variables they need to set to
  #    run FastlaneCI
  #
  # 3) Asks the user to input all their environment variables, and writes them
  #    out to a `.keys` file in the project root
  #
  # 4) Loads the newly written environment variables from the `.keys` file
  #    through `dotenv`
  #
  # 5) Creates a private repository using the `GitHubClient` with the clone
  #    user's API token `FASTLANE_CI_INITIAL_CLONE_API_TOKEN`
  #
  # 6) Prints information about the `users.json` file
  #
  # 7) Asks the user to input variables specific to the `users.json`, file and
  #    writes them out to the `users.json` file in the private configuration repo
  #
  # 8) Prints information about the `projects.json` file
  #
  # 9) Asks the user to input variables specific to the `projects.json`, file and
  #    writes them out to the `projects.json` file in the private configuration
  #    repo
  #
  # 10) Commits the changes to the private configuration repo and pushes them
  #
  class PrivateConfigurationWizard < Wizard
    include ConfigurationInputHelpers
    include GitHubClient

    # Runs the initial configuration wizard, setting up the private GitHub
    # configuration repository
    def run!
      print_welcome_message
      print_keys_file_information
      write_keys_file
      Launch.load_dot_env
      create_private_remote_configuration_repo
      print_users_json_file_information
      write_users_json_file
      print_projects_json_file_information
      write_projects_json_file
      commit_and_push_changes!
    end

    private

    #####################################################
    # @!group Messaging: show text to the user
    #####################################################

    def print_welcome_message
      UI.header("Welcome to FastlaneCI!")
      UI.message(
        <<~MESSAGE
          A mobile-optimized, self-hosted continuous integration platform.

          We've noticed this is your first time running the server. FastlaneCI
          requires some configuration information from you to properly run the
          server.
        MESSAGE
      )
      UI.confirm("Continue with configuration? ")
    end

    def print_keys_file_information
      UI.header(".keys")
      UI.message(
        <<~MESSAGE
          FastlaneCI requires certain environment variables to be configured.
          These environment variables include:

            # Randomly generated key, that's used to encrypt the user passwords
            FASTLANE_CI_ENCRYPTION_KEY='key'

            # The email address of your fastlane CI bot account
            FASTLANE_CI_USER='email-for-your-bot-account@gmail.com'

            # The API token of your fastlane CI bot account
            FASTLANE_CI_PASSWORD='encrypted_api_password'

            # The git URL (https) for the configuration repo
            FASTLANE_CI_REPO_URL='https://github.com/username/reponame'

            # Needed just for the first startup of fastlane.ci:
            # The email address used for the intial clone for the config repo
            FASTLANE_CI_INITIAL_CLONE_EMAIL='email-for-your-clone-account@gmail.com'

            # The API token used for the initial clone for the config repo
            FASTLANE_CI_INITIAL_CLONE_API_TOKEN='api_token_for_initial_clone'
        MESSAGE
      )
      UI.confirm("Continue with configuration? ")
    end

    def print_users_json_file_information
      UI.header("users.json")
      UI.message(
        <<~MESSAGE
          \nIn order to run fastlane.ci for the first time, the #{repo_shortform}
          needs to be populated with at least two files. The first of these
          files is the `users.json` file:

          [
            {
              "id": "auto_generated_id",
              "email": "your-name@gmail.com",
              "password_hash": "Some password hash that needs to be created.",
              "provider_credentials": [
                {
                  "email": "user-email@gmail.com",
                  "encrypted_api_token": "Encrypted GitHub API token",
                  "provider_name": "GitHub",
                  "type": "github",
                  "full_name": "Fastlane CI"
                }
              ]
            }
          ]

          The wizard will now walk you through how to generate all the required
          information:
        MESSAGE
      )
      UI.confirm("Continue with configuration? ")
    end

    def print_projects_json_file_information
      UI.header("projects.json")
      UI.message(
        <<~MESSAGE
          \nIn order to run fastlane.ci for the first time, the #{repo_shortform}
          needs to be populated with at least two files. The second of these
          files is the `projects.json` file:

          [
            {
              "repo_config": {
                "id": "ad0dadd1-ba5a-4634-949f-0ce62b77e48f",
                "git_url": "https://github.com/your-name/fastlane-ci-demoapp",
                "full_name": "your-name/fastlane-ci-demoapp",
                "description": "Fastlane CI Demo App Repository",
                "name": "Fastlane CI Demo App",
                "provider_type_needed": "github",
                "hidden": false
              },
              "id": "db799377-aaa3-4605-ba43-c91a13c8f83",
              "project_name": "fastlane CI demo app test",
              "lane": "test",
              "enabled": true
            }
          ]
        MESSAGE
      )
      UI.confirm("Continue with configuration? ")
    end

    #####################################################
    # @!group Writers: functions to write files
    #####################################################

    # Write .keys configuration file with proper environment variables
    def write_keys_file
      keys_file_path = File.join(FastlaneCI::FastlaneApp.settings.root, ".keys.sample")

      KeysWriter.new(
        path: keys_file_path,
        locals: {
          encryption_key: encryption_key,
          ci_user_email: ci_user_email,
          ci_user_api_token: ci_user_api_token,
          repo_shortform: repo_shortform,
          clone_user_email: clone_user_email,
          clone_user_api_token: clone_user_api_token
        }
      ).write!

      UI.success("Wrote #{keys_file_path}")
    end

    # Writes the `users.json` file to the configuration repo
    def write_users_json_file
      users_json_file_path = configuration_git_repo.file_path("users.json")

      UsersWriter.new(
        path: users_json_file_path,
        locals: {
          ci_user_email: ci_user_email,
          ci_user_api_token: ci_user_api_token
        }
      ).write!

      UI.success("Wrote #{users_json_file_path}")
    end

    # Writes the `projects.json` file to the configuration repo
    def write_projects_json_file
      projects_json_file_path = configuration_git_repo.file_path("projects.json")

      ProjectsWriter.new(
        path: projects_json_file_path,
        locals: {}
      )

      UI.success("Wrote #{projects_json_file_path}")
    end

    #####################################################
    # @!group Helpers: GitHub configuration helpers
    #####################################################

    # Configuration GitRepo
    #
    # @return [GitRepo]
    def configuration_git_repo
      @configuration_git_repo ||= FastlaneCI::GitRepo.new(
        git_config: Launch.ci_config_repo,
        provider_credential: Launch.provider_credential
      )
    end

    # Creates a remote repository. If the operation is unsuccessful, the method
    # throws an exception
    #
    # @raises [StandardError]
    def create_private_remote_configuration_repo
      repo_name = repo_shortform.split("/")[1]
      clone_user_api.create_repository(repo_name, private: true)
    end

    # Commits the most recent changes and pushes them to the new repo
    def commit_and_push_changes!
      configuration_git_repo.commit_changes!
      configuration_git_repo.push
    end
  end
end

# rubocop:enable Layout/EmptyLinesAroundArguments
