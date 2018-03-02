require_relative "./code_hosting/git_hub_service"
require_relative "./config_data_sources/json_project_data_source"
require_relative "./config_service"
require_relative "./data_sources/json_build_data_source"
require_relative "./data_sources/json_user_data_source"
require_relative "./file_writer_service"
require_relative "./project_service"
require_relative "./notification_service"
require_relative "./user_service"
require_relative "./worker_service"

module FastlaneCI
  # A class that stores the singletones for each
  # service we provide
  class Services
    class << self
      attr_reader :ci_config_repo

      def ci_config_repo=(value)
        # When setting a new CI config repo
        # we gotta make sure to also re-init all the other
        # services and variables we use
        # TODO: Verify that we actually need to do this
        @_user_service = nil
        @_build_service = nil
        @_project_service = nil
        @_ci_user = nil
        @_config_service = nil
        @_worker_service = nil

        @ci_config_repo = value
      end
    end

    ########################################################
    # Service helpers
    ########################################################

    # Get the path to where we store fastlane.ci configuration
    def self.ci_config_git_repo_path
      self.ci_config_repo.local_repo_path
    end

    # Configuration GitRepo
    #
    # @return [GitRepo]
    def self.configuration_git_repo
      @configuration_git_repo ||= FastlaneCI::GitRepo.new(
        git_config: Launch.ci_config_repo,
        provider_credential: Launch.provider_credential
      )
    end

    def self.ci_user
      # Find our fastlane.ci system user
      @_ci_user ||= Services.user_service.login(
        email: ENV["FASTLANE_CI_USER"],
        password: ENV["FASTLANE_CI_PASSWORD"],
        ci_config_repo: self.ci_config_repo
      )
    end

    ########################################################
    # Services that we provide
    ########################################################

    # Start up a ProjectService from our JSONProjectDataSource
    def self.project_service
      @_project_service ||= FastlaneCI::ProjectService.new(
        project_data_source: FastlaneCI::JSONProjectDataSource.create(ci_config_repo, user: ci_user)
      )
    end

    # Start up a UserService from our JSONUserDataSource
    def self.user_service
      @_user_service ||= FastlaneCI::UserService.new(
        user_data_source: FastlaneCI::JSONUserDataSource.create(ci_config_git_repo_path)
      )
    end

    # Start up a NotificationService from our JSONNotificationDataSource
    def self.notification_service
      @_notification_service ||= FastlaneCI::NotificationService.new(
        notification_data_source: JSONNotificationDataSource.create(
          File.expand_path("..", ci_config_git_repo_path)
        )
      )
    end

    # Start up the BuildService
    def self.build_service
      @_build_service ||= FastlaneCI::BuildService.new(
        build_data_source: JSONBuildDataSource.create(ci_config_git_repo_path)
      )
    end

    # Grab a config service that is configured for the CI user
    def self.config_service
      @_config_service ||= FastlaneCI::ConfigService.new(ci_user: ci_user)
    end

    def self.worker_service
      @_worker_service ||= FastlaneCI::WorkerService.new
    end

    def self.file_writer_service
      @_file_writer_service ||= FastlaneCI::FileWriterService.new
    end
  end
end
