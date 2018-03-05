require "set"

require_relative "../../shared/authenticated_controller_base"
require_relative "../../services/services"

module FastlaneCI
  # A CRUD controller to manage users
  class UsersController < AuthenticatedControllerBase
    HOME = "/users"

    # When the `/users/create` form is submitted:
    #
    # - creates a user if the locals are valid
    # - returns an error if the locals are not
    post "#{HOME}/create" do
      if valid_params?(params, users_params)
        Services.user_service.create_user!(
          id: params[:id],
          email: params[:email],
          password: params[:password],
          provider_credentials: map_provider_credentials(params)
        )
      end

      redirect back
    end

    # Updates a user existing in the configuration repository `users.json`
    post "#{HOME}/update" do
      if valid_params?(params, users_params)
        new_user = User.new(
          id: params[:id],
          email: params[:email],
          password: params[:password]
        )

        Services.user_service.update_user!(new_user)
      end

      redirect back
    end

    private

    #####################################################
    # @!group Locals: View-specific locals
    #####################################################

    # @return [Set[Symbol]]
    def users_params
      Set.new(%w(id email password_hash provider_email))
    end
  end
end
