# frozen_string_literal: true

module Paginable
  # Controller for paginating/sorting the plan snapshots table
  class PlanSnapshotsController < ApplicationController
    include Paginable

    before_action :set_plan
    before_action :authorize_plan

    # GET /paginable/plans/:plan_id/versions
    # GET /paginable/plans/:plan_id/versions/index/:page
    def index
      paginable_renderise(
        partial: 'index',
        controller: 'paginable/plan_snapshots',
        action: 'index',
        scope: fetch_snapshots,
        locals: { plan: @plan },
        format: :json,
        view_all: true
      )
    end

    private

    def authorize_plan
      authorize @plan, policy_class: PlanSnapshotPolicy
    end

    def set_plan
      @plan = Plan.find(params[:plan_id])
    end

    def fetch_snapshots
      snapshots = PlanSnapshot.for_plan(@plan)
      # Clear default `.for_plan` ordering when user-selected sort params exist.
      return snapshots.unscope(:order) if params[:sort_field].present? || params[:sort_direction].present?

      snapshots
    end
  end
end
