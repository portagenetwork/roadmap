# frozen_string_literal: true

module Users
  # Controller that handles callbacks from OmniAuth integrations (e.g. Shibboleth and ORCID)
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    include EmailConfirmationHandler

    # This is for the OpenidConnect CILogon
    def openid_connect
      auth = request.env['omniauth.auth']
      user = User.from_omniauth(auth)

      # if email missing from IdP and no user with these auth creds exists in DB
      if auth.info.email.nil? && user.nil?
        handle_missing_email_for_new_sso_entry
        return
      end

      identifier_scheme = IdentifierScheme.find_by(name: auth.provider)

      # if user is not signed in (They clicked the SSO sign in button)
      if current_user.nil?
        handle_openid_connect_for_signed_out_user(user, auth, identifier_scheme)
      # else user is signed in (They clicked the SSO link account button)
      else
        handle_openid_connect_for_signed_in_user(user, auth, identifier_scheme)
      end
    end

    def orcid
      handle_omniauth(IdentifierScheme.for_authentication.find_by(name: 'orcid'))
    end

    def shibboleth
      handle_omniauth(IdentifierScheme.for_authentication.find_by(name: 'shibboleth'))
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
               User.from_omniauth(request.env['omniauth.auth'])
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
        else
          flash[:notice] = _('Successfully signed in')
          redirect_to new_user_registration_url
        end

      # The user is already logged in and just registering the uid with us
      else
        # If the user could not be found by that uid then attach it to their record
        if user.nil?
          if Identifier.create(identifier_scheme: scheme,
                               value: request.env['omniauth.auth'].uid,
                               attrs: request.env['omniauth.auth'],
                               identifiable: current_user)
            flash[:notice] =
              format(_('Your account has been successfully linked to %{scheme}.'),
                     scheme: scheme.description)

          else
            flash[:alert] = format(_('Unable to link your account to %{scheme}.'),
                                   scheme: scheme.description)
          end

        elsif user.id != current_user.id
          # If a user was found but does NOT match the current user then the identifier has
          # already been attached to another account (likely the user has 2 accounts)
          # rubocop:disable Layout/LineLength
          flash[:alert] = format(_('The current %{scheme_description} iD has been already linked to a user with email %{identifier_user_email}'), scheme_description: scheme.description, identifier_user_email: identifier.user.email)
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

    private

    def handle_missing_email_for_new_sso_entry
      flash[:alert] = generate_flash_message_for_missing_email
      # Signed out user stays on 'Sign in' page
      # Signed in user stays on 'Edit profile' page
      path = current_user.nil? ? root_path : edit_user_registration_path
      redirect_to path
    end

    def generate_flash_message_for_missing_email
      testidp_url = 'https://cilogon.org/testidp/'
      helpdesk_email = Rails.configuration.x.organisation.helpdesk_email
      # if user is signed out and attempted to sign in via SSO
      if current_user.nil?
        format(
          _('Unable to sign in with the selected identity provider. Consider using an alternative sign in method, ' \
            'like social sign on. You can verify your email is being provided here <%{url}> and contact us at the ' \
            'help desk for further assistance. Help desk email: %{helpdesk_email}'),
          url: view_context.link_to(nil, testidp_url), helpdesk_email: view_context.mail_to(helpdesk_email)
        )
      # else user is signed in and attempted to link a new SSO account
      else
        format(
          _('Unable to link with the selected identity provider. Consider using an alternative sign in method, ' \
            'like social sign on. You can verify your email is being provided here <%{url}> and contact us at the ' \
            'help desk for further assistance. Help desk email: %{helpdesk_email}'),
          url: view_context.link_to(nil, testidp_url), helpdesk_email: view_context.mail_to(helpdesk_email)
        )
      end
    end

    def handle_openid_connect_for_signed_out_user(user, auth, identifier_scheme)
      # user.nil? is true if the chosen CILogon email is not currently linked to an existing user account
      user = handle_new_sso_email_for_signed_out_user(auth, identifier_scheme) if user.nil?
      # See app/controllers/concerns/email_confirmation_handler.rb
      return if confirmation_instructions_missing_and_handled?(user)

      sign_in_and_redirect user, event: :authentication
    end

    # This method is executed when a user performs the following two steps:
    # 1) clicks "Sign in with institutional or social ID"
    # 2) Within CILogon, selects an email that is not currently linked to an existing user account
    def handle_new_sso_email_for_signed_out_user(auth, identifier_scheme)
      # Find or create the user with user.email == email selected via SSO
      user = User.find_or_create_from_provider_data(auth)
      if user.confirmed?
        # Only link the SSO email if user.email is confirmed
        user.identifiers << Identifier.create(identifier_scheme: identifier_scheme,
                                              value: auth.uid,
                                              attrs: auth,
                                              identifiable: user)
      end
      user
    end

    def handle_openid_connect_for_signed_in_user(user, auth, identifier_scheme)
      if user.nil?
        # We need to link the new auth creds
        handle_new_sso_email_for_signed_in_user(auth, identifier_scheme)
      # elsif user is signed in and trying to link via SSO, but the auth creds are already linked to another account
      elsif user.id != current_user.id
        handle_conflicting_sso_email_for_signed_in_user(identifier_scheme, user)
      end
    end

    def handle_new_sso_email_for_signed_in_user(auth, identifier_scheme)
      current_user.identifiers << Identifier.create(identifier_scheme: identifier_scheme,
                                                    value: auth.uid,
                                                    attrs: auth,
                                                    identifiable: current_user)
      flash[:notice] = _('Linked successfully')
      redirect_to edit_user_registration_path
    end

    def handle_conflicting_sso_email_for_signed_in_user(identifier_scheme, user)
      flash[:alert] = format(_('The current %{description} iD has been already linked to a user with email %{email}'),
                             description: identifier_scheme.description, email: user.email)
      redirect_to edit_user_registration_path
    end
  end
end
