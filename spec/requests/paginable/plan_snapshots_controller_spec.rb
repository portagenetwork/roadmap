# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Paginable::PlanSnapshotsController', type: :request do
  let(:plan) { create(:plan, :snapshot_ready) }
  let(:user) { create(:user) }

  before { sign_in(user) }

  def authorize_as(role)
    create(:role, role, plan: plan, user: user)
  end

  describe 'GET /paginable/plans/:plan_id/versions' do
    let!(:older_snapshot) { create(:plan_snapshot, plan: plan, version: 1, created_at: 2.days.ago) }
    let!(:newer_snapshot) { create(:plan_snapshot, plan: plan, version: 2, created_at: 1.day.ago) }

    context 'when authorized' do
      before { authorize_as(:commenter) }

      it 'returns OK with paginable html payload' do
        get paginable_plan_snapshots_path(plan_id: plan.id), xhr: true

        expect(response).to have_http_status(:ok)
        payload = JSON.parse(response.body)
        expect(payload['html']).to include('Identifier')
        expect(payload['html']).to include('Version')
      end

      it 'applies requested sort params by created_at asc' do
        get paginable_plan_snapshots_path(plan_id: plan.id,
                                          sort_field: 'plan_snapshots.created_at',
                                          sort_direction: 'asc'), xhr: true

        payload = JSON.parse(response.body)
        html = payload['html']

        first_version_index = html.index("<td>#{older_snapshot.version}</td>")
        second_version_index = html.index("<td>#{newer_snapshot.version}</td>")

        expect(first_version_index).not_to be_nil
        expect(second_version_index).not_to be_nil
        expect(first_version_index).to be < second_version_index
      end

      it 'uses default ordering by version desc when sort params are absent' do
        get paginable_plan_snapshots_path(plan_id: plan.id), xhr: true

        payload = JSON.parse(response.body)
        html = payload['html']

        first_version_index = html.index("<td>#{newer_snapshot.version}</td>")
        second_version_index = html.index("<td>#{older_snapshot.version}</td>")

        expect(first_version_index).not_to be_nil
        expect(second_version_index).not_to be_nil
        expect(first_version_index).to be < second_version_index
      end
    end

    context 'when unauthorized' do
      it 'redirects as unauthorized' do
        get paginable_plan_snapshots_path(plan_id: plan.id), xhr: true

        expect(response).to redirect_to(plans_url)
        follow_redirect!

        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end
    end
  end
end
