# frozen_string_literal: true

class Api::V0::PlansController < Api::V0::BaseController

  before_action :authenticate

  ##
  # Creates a new plan based on the information passed in JSON to the API
  def create
    @template = Template.live(params[:template_id])
    unless Api::V0::PlansPolicy.new(@user, @template).create?
      raise Pundit::NotAuthorizedError
    end

    plan_user = User.find_by(email: params[:plan][:email])
    # ensure user exists
    if plan_user.blank?
      User.invite!({ email: params[:plan][:email] }, @user)
      plan_user = User.find_by(email: params[:plan][:email])
      plan_user.org = @user.org
      plan_user.save
    end
    # ensure user's organisation is the same as api user's
    unless plan_user.org == @user.org
      raise Pundit::NotAuthorizedError, _("user must be in your organisation")
    end

    # initialize the plan
    @plan = Plan.new
    if plan_user.surname.blank?
      @plan.principal_investigator = nil
    else
      @plan.principal_investigator = plan_user.anem(false)
    end

    @plan.data_contact = plan_user.email
    # set funder name to template's org, or original template's org
    if @template.customization_of.nil?
      @plan.funder_name = @template.org.name
    else
      @plan.funder_name = Template.where(
        family_id: @template.customization_of
      ).first.org.name
    end
    @plan.template = @template
    @plan.title = params[:plan][:title]
    if @plan.save
      @plan.assign_creator(plan_user)
      respond_with @plan
    else
      # the plan did not save
      self.headers["WWW-Authenticate"] = "Token realm=\"\""
      render json: _("Bad Parameters"), status: 400
    end
  end

  def index
    unless Api::V0::PlansPolicy.new(@user, nil).index?
      raise Pundit::NotAuthorizedError
    end
    @plans = @user.org.plans.includes( [ {answers: :question_options} ,
      template: [ { phases: { sections: { questions: :question_format } } }, :org]
    ])
    paginate @plans, per_page: 20
  end

end
