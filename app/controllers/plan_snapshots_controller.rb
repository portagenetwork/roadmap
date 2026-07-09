# frozen_string_literal: true

# Controller responsible for managing plan snapshots
class PlanSnapshotsController < ApplicationController
  JSON_GENERATION_ERROR_ATTRIBUTES = %i[rda_json extension_json].freeze

  before_action :set_plan
  before_action :authorize_plan
  before_action :set_snapshot, only: [:show]

  # GET /plans/:plan_id/versions
  def index
    render locals: {
      plan: @plan,
      snapshots: PlanSnapshot.for_plan(@plan),
      can_create_snapshot: PlanSnapshotPolicy.new(current_user, @plan).create?,
      snapshot_blockers: @plan.snapshot_blockers
    }
  end

  # GET /plans/:plan_id/versions/:id
  def show
    result = PlanSnapshots::FixityCheckService.new(@snapshot).call
    if result[:status] == :failed
      render json: {
        error: _('There was an error detected. The administrators of the repository have been alerted. ' \
                 'A check on (metadata/plan data) did not find matching checksums.')
      }, status: :unprocessable_entity
    else
      render json: @snapshot.rda_json.merge(@snapshot.extension_json)
    end
  end

  # POST /plans/:plan_id/versions
  def create
    snapshot = PlanSnapshot.create_from_plan(plan: @plan, visibility: plan_snapshot_params[:visibility])

    if snapshot.persisted?
      redirect_to plan_snapshots_path(@plan),
                  notice: _('New version published.')
    else
      redirect_to plan_snapshots_path(@plan),
                  alert: create_failure_alert(snapshot)
    end
  end

  private

  def authorize_plan
    authorize @plan, policy_class: PlanSnapshotPolicy
  end

  def set_plan
    @plan = Plan.find(params[:plan_id])
  end

  def set_snapshot
    @snapshot = @plan.snapshots.find(params[:id])
  end

  def plan_snapshot_params
    params.fetch(:plan_snapshot, {}).permit(:visibility)
  end

  def create_failure_alert(snapshot)
    if json_generation_failure?(snapshot)
      notify_json_generation_failure(snapshot)
      _('An error was detected and a new version cannot be published at this time. ' \
        'The administrators of the repository have been alerted.')
    else
      failure_message(snapshot, _('create'))
    end
  end

  def json_generation_failure?(snapshot)
    snapshot.errors.attribute_names.any? { |attr| JSON_GENERATION_ERROR_ATTRIBUTES.include?(attr.to_sym) }
  end

  def notify_json_generation_failure(snapshot)
    payload = json_generation_alert_payload(snapshot)
    failure_message = 'Plan snapshot JSON generation failed'
    Rails.logger.error(
      payload.merge(
        message: failure_message
      )
    )

    Rollbar.error(failure_message, payload)
  end

  def json_generation_alert_payload(snapshot)
    {
      plan_id: @plan.id,
      user_id: current_user&.id,
      errors: snapshot.errors.to_hash(true)
    }
  end
end
