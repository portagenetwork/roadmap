# frozen_string_literal: true

module Users
  # Controller that handles callbacks from OmniAuth integrations (e.g. Shibboleth and ORCID)
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    ##
    # Dynamically build a handler for each omniauth provider
    # -------------------------------------------------------------
    IdentifierScheme.for_authentication.each do |scheme|
      define_method(scheme.name.downcase) do
        handle_omniauth(scheme)
      end
    end
  
    def cilogon
      # XXX These loggers needs to be removed and other way around. XXX
      Rails.logger.debug request.env['rack.session']['omniauth.state'].inspect
      # handle_omniauth "cilogonauth"

        auth = request.env['omniauth.auth']
        Rails.logger.info "OmniAuth Auth Hash: #{auth.inspect}"
        if auth
          access_token = auth['credentials']['token']
    
          # Store the access token in the session or database
          session[:access_token] = access_token
    
          # Find or create the user based on the auth data 
          # XXX This will be going to the user model once we have this fully funtioning. XXX
          @user = User.find_or_create_by(uid: auth['info']['eppn']) do |user|
            user.email = auth['info']['email']
            user.password = Devise.friendly_token[0, 20]
            user.name = auth['info']['name']
          end
    
          if @user.persisted?
            sign_in_and_redirect @user, event: :authentication
            set_flash_message(:notice, :success, kind: 'CILogon') if is_navigational_format?
          else
            session["devise.cilogon_data"] = auth.except("extra")
            redirect_to new_user_registration_url
          end
        else
          Rails.logger.error "OmniAuth Auth Hash is nil"
          redirect_to new_user_session_path, alert: "Authentication failed."
        end
      end
    
      def failure
        #XXX handling the failue of nil value on omniauth would be here XXX
        Rails.logger.error "OmniAuth Authentication Failure: #{params[:message]}"
        redirect_to root_path, alert: "Authentication failed."
      end

    # Processes callbacks from an omniauth provider and directs the user to
    # the appropriate page:
    #   Not logged in and uid had no match ---> Sign Up page
    #   Not logged in and uid had a match ---> Sign In and go to Home Page
    #   Signed in and uid had no match --> Save the uid and go to the Profile Page
    #   Signed in and uid had a match --> Go to the Home Page
    #
    # scheme - The IdentifierScheme for the provider
    #
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def handle_omniauth(scheme)
      user = if request.env['omniauth.auth'].nil?
               User.from_omniauth(request.env)
            else 
               User.from_omniauth(request.env['rack.session'] )
             end

      # If the user isn't logged in
      if current_user.nil?
        # If the uid didn't have a match in the system send them to register
        if user.nil?
          session["devise.#{scheme.name.downcase}_data"] = request.env['omniauth.auth']
          redirect_to new_user_registration_url

        # Otherwise sign them in
        elsif scheme.name == 'shibboleth'
          # Until ORCID becomes supported as a login method
          set_flash_message(:notice, :success, kind: scheme.description) if is_navigational_format?
          sign_in_and_redirect user, event: :authentication
        elsif schema.name == "cilogon"
          if user.persisted?
            sign_in_and_redirect user, event: :authentication
            set_flash_message(:notice, :success, kind: "CILogon") if is_navigational_format?
          else
            session["devise.cilogon_data"] = request.env['rack.session']['omniauth.nonce']
            redirect_to new_user_registration_url
          end
        else
          flash[:notice] = _('Successfully signed in')
          redirect_to new_user_registration_url
        end

      # The user is already logged in and just registering the uid with us
      else
        # If the user could not be found by that uid then attach it to their record
        if user.nil?
          if Identifier.create(identifier_scheme: scheme,
                               value: request.env['rack.session']['omniauth.state'],#request.env['omniauth.auth'].uid,
                               attrs: request.env['rack.session']['omniauth.nonce'],#request.env['omniauth.auth'],
                               identifiable: current_user)
            flash[:notice] =
              format(_('Your account has been successfully linked to %{scheme}.'),
                     scheme: scheme.description)
            redirect_to new_user_registration_url

          else
            flash[:alert] = format(_('Unable to link your account to %{scheme}.'),
                                   scheme: scheme.description)
          end

        elsif user.id != current_user.id
          # If a user was found but does NOT match the current user then the identifier has
          # already been attached to another account (likely the user has 2 accounts)
          # rubocop:disable Layout/LineLength
          flash[:alert] = _("The current #{scheme.description} iD has been already linked to a user with email #{identifier.user.email}")
          # rubocop:enable Layout/LineLength
        end

        # Redirect to the User Profile page
        redirect_to edit_user_registration_path
      end
    end



    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def failure
      redirect_to root_path
    end
  end
end
