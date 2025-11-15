# frozen_string_literal: true

class PlanSnapshotsController < ApplicationController
  # POST /plans/:plan_id/plan_snapshots
  def create
    plan = Plan.find(params[:plan_id])
    snapshot = PlanSnapshot.create_for_plan(plan, visibility: params[:plan_snapshot][:visibility])

    # Mint the snapshot if it is publicly visible
    # TODO: Should minting occur if RDA metadata is identical to last version?
    DmpIdService.mint_dmp_id(plan: plan, snapshot: snapshot) if snapshot.publicly_visible?

    ConnectDataciteDoisJob.perform_later(plan: plan, snapshot: snapshot)

    redirect_to plan, notice: 'New version published.'
  end
end
