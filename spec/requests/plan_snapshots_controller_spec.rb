# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PlanSnapshotsController', type: :request do
  let(:plan) { create(:plan) }

  let(:administrator) { create(:user) }
  let(:editor) { create(:user) }
  let(:commenter) { create(:user) }
  let(:other_user) { create(:user) }

  let(:visibility) { PlanSnapshot.visibilities.keys.first }
  let(:post_params) { { plan_snapshot: { visibility: visibility } } }

  before do
    create(:role, :administrator, plan: plan, user: administrator)
  end

  shared_examples 'can view the snapshot' do
    subject(:perform_request) { get request_path }

    let(:json) { JSON.parse(response.body) }

    it 'returns the snapshot JSON' do
      perform_request

      expect(response).to have_http_status(:ok)
      expect(json).to include(
        snapshot.rda_json.merge(snapshot.extension_json)
      )
    end
  end

  shared_examples 'redirects as unauthorized' do |http_method, params = {}|
    subject(:perform_request) { public_send(http_method, request_path, params: params) }

    it 'redirects with a not-authorized message' do
      perform_request

      expect(response).to redirect_to(plans_url)

      follow_redirect!
      expect(flash[:alert]).to eq('You are not authorized to perform this action.')
    end
  end

  shared_examples 'cannot create snapshot' do
    it 'does not create a snapshot' do
      expect do
        post request_path, params: post_params
      end.not_to change(plan.snapshots, :count)

      expect(response).to redirect_to(plans_url)
    end
  end

  describe 'GET /plans/:plan_id/versions/:id' do
    let(:snapshot) { create(:plan_snapshot, plan: plan, version: 1) }
    let(:request_path) { plan_snapshot_path(plan, snapshot) }

    context 'as an administrator' do
      before do
        sign_in(administrator)
      end

      include_examples 'can view the snapshot'
    end

    context 'as a commenter' do
      before do
        create(:role, :commenter, plan: plan, user: commenter)
        sign_in(commenter)
      end

      include_examples 'can view the snapshot'
    end

    context 'without access to the plan' do
      before do
        sign_in(other_user)
      end

      include_examples 'redirects as unauthorized', :get
    end

    context 'when fixity check fails' do
      before do
        PlanSnapshots::FixityCheckService
          .stubs(:new)
          .returns(stub(call: { status: :failed }))
      end

      before do
        sign_in(administrator)
      end

      it 'returns an error response' do
        get request_path

        expect(response).to have_http_status(:unprocessable_entity)

        json = JSON.parse(response.body)
        expect(json['error']).to be_present
      end
    end
  end

  describe 'POST /plans/:plan_id/versions' do
    let(:request_path) { plan_snapshots_path(plan) }

    context 'as an administrator' do
      before do
        sign_in(administrator)
      end

      it 'publishes a snapshot' do
        expect do
          post request_path, params: post_params
        end.to change(plan.snapshots, :count).by(1)

        snapshot = plan.snapshots.order(:version).last

        expect(snapshot.visibility).to eq(visibility)
        expect(response).to redirect_to(plan_path(plan))
        expect(flash[:notice]).to eq('New version published.')
      end
    end

    context 'as an editor' do
      before do
        create(:role, :editor, plan: plan, user: editor)
        sign_in(editor)
      end

      include_examples 'cannot create snapshot'
    end

    context 'as a commenter' do
      before do
        create(:role, :commenter, plan: plan, user: commenter)
        sign_in(commenter)
      end

      include_examples 'cannot create snapshot'
    end

    context 'without access to the plan' do
      before do
        sign_in(other_user)
      end

      include_examples 'cannot create snapshot'
    end
  end
end
