# frozen_string_literal: true

# Security rules for plan_snapshots
# - NOTE: Rather than the plan_snapshot itself,
#   here we are using @record == plan_snapshot.plan.
class PlanSnapshotPolicy < ApplicationPolicy
  # @record is the underlying plan
  def show?
    @record.readable_by?(@user.id)
  end

  # @record is the underlying plan
  def create?
    @record.administerable_by?(@user.id)
  end
end
