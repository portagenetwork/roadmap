# frozen_string_literal: true

# Security rules for plan_snapshots
# - NOTE: Rather than the plan_snapshot itself,
#   here we are using @record == plan_snapshot.plan.
class PlanSnapshotPolicy < ApplicationPolicy
  def index?
    plan_readable_by_user?
  end

  def show?
    plan_readable_by_user?
  end

  # @record is the underlying plan
  def create?
    @record.administerable_by?(@user.id)
  end

  def tombstone?
    return false unless user.present? && user.can_super_admin?
    return true unless record.is_a?(PlanSnapshot)

    record.publicly_visible? && !record.tombstoned?
  end

  private

  # @record is the underlying plan
  def plan_readable_by_user?
    @record.readable_by?(@user.id)
  end
end
