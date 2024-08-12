# frozen_string_literal: true

module Users
  # Controller that handles callbacks from OmniAuth integrations (e.g. Shibboleth and ORCID)
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    def openid_connect
      # First or create
      auth = request.env['omniauth.auth']
      user = User.from_omniauth(auth)


      if auth.info.email.nil? && user.nil?
        #If email is missing we need to request the user to register with DMP. 
        #User email can be missing if the user email id is set to private or trusted clients only we won't get the value. 
        #USer email id is one of the mandatory field which is must required.
        flash[:notice] = 'provided user email is wrong or ORCID private email. Please try again with ORCID public email OR try sign-up with DMP assistant.'
        redirect_to new_user_registration_path
      elsif current_user.nil?
        # We need to register

        if user.nil?
          # Register and sign in

          user = User.create_from_provider_data(auth)
          identifier_scheme = IdentifierScheme.find_by_name(auth.provider)
          Identifier.create(identifier_scheme: identifier_scheme, #auth.provider, #scheme, #IdentifierScheme.last.id,
                            value: auth.uid,
                            attrs: auth,
                            identifiable: user)

        end

        sign_in_and_redirect user, event: :authentication

      elsif user.nil?

        # we need to link
        Identifier.create(identifier_scheme: scheme,
                          value: auth.uid,
                          attrs: auth,
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
