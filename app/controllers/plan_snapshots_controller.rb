# frozen_string_literal: true

# Controller responsible for managing plan snapshots
class PlanSnapshotsController < ApplicationController
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
    snapshot = PlanSnapshot.create_from_plan(plan: @plan, visibility: params[:plan_snapshot][:visibility])

    if snapshot.persisted?
      redirect_to plan_snapshots_path(@plan),
                  notice: _('New version published.')
    else
      redirect_to plan_snapshots_path(@plan),
                  alert: failure_message(snapshot, _('create'))
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
end
