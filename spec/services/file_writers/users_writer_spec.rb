require File.expand_path("../../../spec_helper.rb", __FILE__)
require File.expand_path("../../../../services/file_writers/users_writer.rb", __FILE__)

describe FastlaneCI::UsersWriter do
  before(:each) do
    stub_file_io
  end

  let(:fixtures_path) do
    File.join(
      FastlaneCI::FastlaneApp.settings.root,
      "spec/fixtures/files/templates"
    )
  end

  let(:template_path) do
    File.join(fixtures_path, "users_template.json")
  end

  let (:template_string) do
    File.read(template_path)
  end

  subject do
    described_class.new(
      path: template_path,
      locals: {
        ci_user_email: "ci_user_email",
        ci_user_api_token: "ci_user_api_token"
      }
    )
  end

  describe "#write!" do
    it "opens and writes the `file_template` to the `path`, with the correct `locals`" do
      subject.stub(:ci_user_encrypted_api_token) { "ci_user_encrypted_api_token" }
      subject.stub(:password_hash) { "password_hash" }
      SecureRandom.stub(:uuid) { "random-uuid" }

      file = double("file")

      File
        .should_receive(:open)
        .with(template_path, "w")
        .and_yield(file)

      file
        .should_receive(:write)
        .with(template_string)

      subject.write!
    end
  end
end
