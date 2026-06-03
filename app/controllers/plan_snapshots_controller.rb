# frozen_string_literal: true

# Controller responsible for managing plan snapshots
class PlanSnapshotsController < ApplicationController
  before_action :set_plan
  before_action :authorize_plan
  before_action :set_snapshot, only: [:show]

  # GET /plans/:plan_id/versions/:id
  def show
    render json: @snapshot.rda_json.merge(@snapshot.extension_json)
  end

  # POST /plans/:plan_id/versions
  def create
    PlanSnapshot.create_from_plan(plan: @plan, visibility: params[:plan_snapshot][:visibility])
    redirect_to @plan, notice: _('New version published.')
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
