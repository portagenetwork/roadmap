# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlanSnapshotPolicy, type: :policy do
  subject { described_class.new(user, plan) }

  let(:plan) { create(:plan) }
  let(:user) { create(:user) }

  shared_examples 'permits read access' do |action|
    it "permits #{action}" do
      is_expected.to permit_action(action)
    end
  end

  shared_examples 'forbids read access' do |action|
    it "forbids #{action}" do
      is_expected.to forbid_action(action)
    end
  end

  describe '#index?' do
    context 'when user can read the plan' do
      before do
        create(:role, :commenter, plan: plan, user: user)
      end

      include_examples 'permits read access', :index
    end

    context 'when user cannot read the plan' do
      include_examples 'forbids read access', :index
    end
  end

  describe '#show?' do
    context 'when user can read the plan' do
      before do
        create(:role, :commenter, plan: plan, user: user)
      end

      include_examples 'permits read access', :show
    end

    context 'when user cannot read the plan' do
      include_examples 'forbids read access', :show
    end
  end

  describe '#create?' do
    context 'when user can administer the plan' do
      before do
        create(:role, :administrator, plan: plan, user: user)
      end

      it 'permits snapshot creation' do
        is_expected.to permit_action(:create)
      end
    end

    context 'when user cannot administer the plan' do
      it 'forbids snapshot creation' do
        is_expected.to forbid_action(:create)
      end
    end
  end
end
