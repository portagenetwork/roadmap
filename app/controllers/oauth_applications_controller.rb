# frozen_string_literal: true

# Custom controller to extend Doorkeeper::ApplicationsController
# https://github.com/doorkeeper-gem/doorkeeper/blob/main/app/controllers/doorkeeper/applications_controller.rb
class OauthApplicationsController < Doorkeeper::ApplicationsController
  REGEN_SECRET_SUCCESS_MSG = _('Application secret has been regenerated. ' \
                               'Please copy it now and store it somewhere safely. ' \
                               'It will disappear after you leave or refresh this page.')

  # NOTE: Doorkeeper config's `admin_authenticator` controls access to the admin
  # interface at a higher level

  # `set_application` exists in the controller we are extending from
  # - Skip actions that do not utilize application_id
  before_action :set_application, except: %i[index new create]
  # Index filters within action; new/create do not have persisted applications to authorize
  before_action :authorize_application_access!, except: %i[index new create]

  # GET /oauth/applications
  def index
    super
    return if current_user.can_super_admin?

    # Non-super admins with `manage_oauth_apps` can only view their own apps
    @applications = @applications.where(user_id: current_user.id)
  end

  # POST /oauth/applications/:id/regenerate_secret
  def regenerate_secret
    @application.renew_secret
    @application.save!

    flash[:notice] = REGEN_SECRET_SUCCESS_MSG
    flash[:application_secret] = @application.plaintext_secret

    redirect_to oauth_application_path(@application)
  rescue StandardError => e
    flash[:alert] = format(_('Failed to regenerate secret: %{error}'), error: e.message)
    redirect_to oauth_application_path(@application)
  end

  private

  def authorize_application_access!
    # Super admins can access show action for any app
    return if action_name == 'show' && current_user.can_super_admin?

    # Otherwise, current_user must own the app they are accessing
    handle_unauthorized_user unless user_is_app_owner?
  end

  # Merges `user_id` with the default permitted fields (:name, :redirect_uri, etc.)
  # (application_params is used by the default controller's create and update actions)
  def application_params
    super.merge(user_id: current_user.id)
  end

  def user_is_app_owner?
    @application.user_id == current_user.id
  end

  def handle_unauthorized_user
    redirect_to root_path,
                alert: _('You are not authorized to perform this action.')
  end
end
