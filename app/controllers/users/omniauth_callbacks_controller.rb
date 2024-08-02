# frozen_string_literal: true

module Users
  # Controller that handles callbacks from OmniAuth integrations (e.g. Shibboleth and ORCID)
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def openid_connect
      # First or create
      user = User.from_omniauth(request.env['omniauth.auth'])

      if current_user.nil?
        # We need to register

        if user.nil?
          # Register and sign in
          user = User.create_from_provider_data(request.env['omniauth.auth'])
          Identifier.create(identifier_scheme: IdentifierScheme.last,
                            value: request.env['omniauth.auth'].uid,
                            attrs: request.env['omniauth.auth'],
                            identifiable: user)

        end

        sign_in_and_redirect user, event: :authentication

      elsif user.nil?

        # we need to link
        Identifier.create(identifier_scheme: scheme,
                          value: request.env['omniauth.auth'].uid,
                          attrs: request.env['omniauth.auth'],
                          identifiable: current_user)

        flash[:notice] = 'linked succesfully'
        redirect_to root_path
      end
    end

    def failure
      redirect_to root_path
    end
  end
end
