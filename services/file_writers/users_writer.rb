# frozen_string_literal: true

require_relative "file_writer"

module FastlaneCI
  # The `users.json` file template, to be stored in the configuration git repo
  class UsersWriter < FileWriter
    # @return [String]
    def file_template
      <<~FILE
        [
          {
            "id": "#{SecureRandom.uuid}",
            "email": "#{locals[:ci_user_email]}",
            "password_hash": "#{password_hash}",
            "provider_credentials": [
              {
                "email": "#{locals[:ci_user_email]}",
                "encrypted_api_token": "#{ci_user_encrypted_api_token}",
                "provider_name": "GitHub",
                "type": "github",
                "full_name": "Fastlane CI"
              }
            ]
          }
        ]
      FILE
    end

    private

    # Encrypted CI user API token
    #
    # @return [String]
    def ci_user_encrypted_api_token
      @ci_user_encrypted_api_token ||= begin
        new_encrypted_api_token = StringEncrypter.encode(locals[:ci_user_api_token])
        Base64.encode64(new_encrypted_api_token)
              .gsub("\r", '\\r')
              .gsub("\n", '\\n')
      end
    end

    # Returns a password hash for the CI user API token
    #
    # @return [String]
    def password_hash
      BCrypt::Password.create(locals[:ci_user_api_token])
    end
  end
end
