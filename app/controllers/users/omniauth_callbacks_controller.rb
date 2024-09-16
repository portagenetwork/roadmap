# frozen_string_literal: true

module Users
  # Controller that handles callbacks from OmniAuth integrations (e.g. Shibboleth and ORCID)
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    # This is for the OpenidConnect CILogon

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def openid_connect
      # First or create
      auth = request.env['omniauth.auth']
      user = User.from_omniauth(auth)

      if auth.info.email.nil? && user.nil?
        # If email is missing we need to request the user to register with DMP.
        # User email can be missing if the usFFvate or trusted clients only we won't get the value.
        # User email id is one of the mandatory field which is must required.
        flash[:notice] = _('Something went wrong, Please try signing up here.')
        redirect_to new_user_registration_path
        return
      end

      identifier_scheme = IdentifierScheme.find_by(name: auth.provider)

      if current_user.nil? # if user is not signed in (They clicked the SSO sign in button)
        if user.nil? # If an entry does not exist in the identifiers table for the chosen SSO account
          user = User.create_from_provider_data(auth)
          if user.nil? # if a user was NOT created (a match was found for User.find_by(email: auth.info.email)
            # Do not link SSO credentials for the signed out, existing user
            flash[:alert] = _('The email you selected has not yet been linked to an existing account.<br>' \
                              "Please sign in via the 'Sign in' button and navigate to the " \
                              "'Edit Profile' section of DMP Assistant.<br>" \
                              'From there you can link an email and enable single sign on access.<br>')
            redirect_to root_path
            return
          end
          # A new user was created, link the SSO credentials (we can do this for a newly created user)
          user.identifiers << Identifier.create(identifier_scheme: identifier_scheme,
                                                value: auth.uid,
                                                attrs: auth,
                                                identifiable: user)
        end
        sign_in_and_redirect user, event: :authentication
      elsif user.nil?
        # we need to link
        current_user.identifiers << Identifier.create(identifier_scheme: identifier_scheme,
                                                      value: auth.uid,
                                                      attrs: auth,
                                                      identifiable: current_user)

        flash[:notice] = _('Linked successfully')

        redirect_to root_path
      elsif user.id != current_user.id
        # If a user was found but does NOT match the current user then the identifier has
        # already been attached to another account (likely the user has 2 accounts)
        flash[:alert] = format(_('The current %{description} iD has been already linked to a user with email %{email}'),
                               description: identifier_scheme.description, email: user.email)
        redirect_to edit_user_registration_path
      end
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

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
  end
end
