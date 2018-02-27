# frozen_string_literal: true

require_relative "file_writer"

module FastlaneCI
  # The `projects.json` file template, to be stored in the configuration git repo
  class ProjectsWriter < FileWriter
    # @return [String]
    def file_template
      <<~FILE
        [
          {
            "repo_config": {
              "id": "#{SecureRandom.uuid}",
              "git_url": "https://github.com/your-name/fastlane-ci-demoapp",
              "full_name": "your-name/fastlane-ci-demoapp",
              "description": "Fastlane CI Demo App Repository",
              "name": "Fastlane CI Demo App",
              "provider_type_needed": "github",
              "hidden": false
            },
            "id": "#{SecureRandom.uuid}",
            "project_name": "fastlane CI demo app test",
            "lane": "test",
            "enabled": true
          }
        ]
      FILE
    end
  end
end
