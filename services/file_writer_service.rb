require_relative "./file_writers/keys_writer.rb"
require_relative "./file_writers/projects_writer.rb"
require_relative "./file_writers/users_writer.rb"

module FastlaneCI
  # Writes stuff lol
  class FileWriterService
    #####################################################
    # @!group Writers: functions to write files
    #####################################################

    # Write .keys configuration file with proper environment variables
    def write_keys_file!(
      locals: {
        encryption_key: nil,
        ci_user_email: nil,
        ci_user_api_token: nil,
        repo_shortform: nil,
        clone_user_email: nil,
        clone_user_api_token: nil
      }
    )
      keys_file_path = File.join(FastlaneCI::FastlaneApp.settings.root, ".keys.sample")
      KeysWriter.new(path: keys_file_path, locals: locals).write!
    end

    # Writes the `users.json` file to the configuration repo
    def write_users_json_file!(
      locals: {
        ci_user_email: nil,
        ci_user_api_token: nil
      }
    )
      users_json_file_path = Services.configuration_git_repo.file_path("users.json")
      UsersWriter.new(path: users_json_file_path, locals: locals).write!
    end

    # Writes the `projects.json` file to the configuration repo
    def write_projects_json_file!(locals: { project_full_name: nil })
      projects_json_file_path = Services.configuration_git_repo.file_path("projects.json")
      ProjectsWriter.new(path: projects_json_file_path, locals: locals).write!
    end
  end
end
