# frozen_string_literal: true

# Custom controller to extend Doorkeeper::ApplicationsController
# https://github.com/doorkeeper-gem/doorkeeper/blob/main/app/controllers/doorkeeper/applications_controller.rb
class OauthApplicationsController < Doorkeeper::ApplicationsController
  # NOTE: Doorkeeper config's `admin_authenticator` controls access to the admin
  # interface at a higher level
  before_action :authorize_application_access!, only: %i[show edit update destroy]

  # GET /oauth/applications
  def index
    super
    return if current_user.can_super_admin?

    # Non-super admins with `manage_oauth_apps` can only view their own apps
    @applications = @applications.where(user_id: current_user.id)
  end

  private

  def authorize_application_access!
    case action_name
    when 'show'
      handle_unauthorized_user unless current_user.can_super_admin? || user_is_app_owner?
    when 'edit', 'update', 'destroy'
      # Actions restricted to app owner
      handle_unauthorized_user unless user_is_app_owner?
    end
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
