# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'PlanSnapshotsController', type: :request do
  let(:plan) { create(:plan, :snapshot_ready) }
  let(:user) { create(:user) }

  let(:visibility) { PlanSnapshot.visibilities.keys.first }
  let(:post_params) { { plan_snapshot: { visibility: visibility } } }

  before { sign_in(user) }

  def json
    JSON.parse(response.body)
  end

  def authorize_as(role)
    create(:role, role, plan: plan, user: user)
  end

  shared_examples 'an authorized request' do
    it 'returns 200 OK' do
      subject
      expect(response).to have_http_status(:ok)
    end
  end

  shared_examples 'an unauthorized request' do
    it 'redirects as unauthorized' do
      subject

      expect(response).to redirect_to(plans_url)
      follow_redirect!

      expect(flash[:alert]).to eq('You are not authorized to perform this action.')
    end
  end

  shared_examples 'returns snapshot json' do
    it 'includes snapshot data' do
      subject

      expect(json).to include(
        snapshot.rda_json.merge(snapshot.extension_json)
      )
    end
  end

  describe 'GET /plans/:plan_id/versions' do
    let(:snapshot) { create(:plan_snapshot, plan: plan) }
    let(:request_path) { plan_snapshots_path(plan) }
    subject { get request_path }

    before { create(:plan_snapshot, plan: plan) }

    context 'when authorized' do
      before { authorize_as(:commenter) }

      include_examples 'an authorized request'
    end

    context 'when unauthorized' do
      include_examples 'an unauthorized request'
    end
  end

  describe 'GET /plans/:plan_id/versions/:id' do
    let(:snapshot) { create(:plan_snapshot, plan: plan) }
    let(:request_path) { plan_snapshot_path(plan, snapshot) }
    subject { get request_path }

    context 'when authorized' do
      before do
        authorize_as(:commenter)
        PlanSnapshots::FixityCheckService.stubs(:new).returns(stub(call: { status: :ok }))
      end

      include_examples 'an authorized request'
      include_examples 'returns snapshot json'
    end

    context 'when fixity check fails' do
      before do
        authorize_as(:administrator)

        PlanSnapshots::FixityCheckService
          .stubs(:new)
          .returns(stub(call: { status: :failed, error: 'corrupt' }))
      end

      it 'returns unprocessable entity' do
        subject

        expect(response).to have_http_status(:unprocessable_entity)
        expect(json['error']).to be_present
      end
    end

    context 'when unauthorized' do
      include_examples 'an unauthorized request'
    end
  end

  describe 'POST /plans/:plan_id/versions' do
    let(:request_path) { plan_snapshots_path(plan) }
    subject { post request_path, params: post_params }

    context 'when authorized' do
      before { authorize_as(:administrator) }

      it 'creates a snapshot' do
        expect { subject }.to change(plan.snapshots, :count).by(1)

        expect(response).to redirect_to(plan_snapshots_path(plan))

        expect(plan.snapshots.order(:version).last.visibility).to eq(visibility)
      end
    end

    context 'when the plan is not ready for snapshot creation' do
      let(:invalid_snapshot) do
        snapshot = PlanSnapshot.new
        snapshot.errors.add(:plan, 'is not ready for snapshot creation')
        snapshot
      end

      before do
        authorize_as(:administrator)
        PlanSnapshot
          .stubs(:create_from_plan)
          .returns(invalid_snapshot)
      end

      it 'does not create a snapshot and redirects with an alert' do
        expect { subject }.not_to change(plan.snapshots, :count)

        expect(response).to redirect_to(plan_snapshots_path(plan))
        expect(flash[:alert]).to include('Unable to create the version.')
        expect(flash[:alert]).to include('Plan is not ready for snapshot creation')
      end
    end

    context 'when the plan has not changed since the previous snapshot' do
      let(:invalid_snapshot) do
        snapshot = PlanSnapshot.new
        snapshot.errors.add(:base,
                            'A new version cannot be published because the plan has not changed since the last version')
        snapshot
      end

      before do
        authorize_as(:administrator)
        PlanSnapshot
          .stubs(:create_from_plan)
          .returns(invalid_snapshot)
      end

      it 'does not create a snapshot and redirects with an alert' do
        expect { subject }.not_to change(plan.snapshots, :count)

        expect(response).to redirect_to(plan_snapshots_path(plan))
        expect(flash[:alert]).to include('Unable to create the version.')
        expect(flash[:alert]).to include(
          'A new version cannot be published because the plan has not changed since the last version'
        )
      end
    end

    context 'when generated snapshot JSON is missing required fields' do
      let(:invalid_snapshot) do
        snapshot = PlanSnapshot.new
        snapshot.errors.add(:rda_json, 'Required fields are missing from the generated JSON')
        snapshot
      end

      before do
        authorize_as(:administrator)
        PlanSnapshot
          .stubs(:create_from_plan)
          .returns(invalid_snapshot)
      end

      it 'does not create a snapshot and redirects with a generic alert' do
        ActionMailer::Base.deliveries.clear

        expect do
          subject
        end.to change(ActionMailer::Base.deliveries, :count).by(1)
                                                            .and change(plan.snapshots, :count).by(0)

        expect(response).to redirect_to(plan_snapshots_path(plan))
        expect(flash[:alert]).to eq(
          'An error was detected and a new version cannot be published at this time. ' \
          'The administrators of the repository have been alerted.'
        )
      end
    end

    context 'when plan_snapshot params are missing' do
      let(:post_params) { {} }

      before { authorize_as(:administrator) }

      it 'creates a privately visible snapshot and redirects with a notice' do
        expect { subject }.to change(plan.snapshots, :count).by(1)

        expect(response).to redirect_to(plan_snapshots_path(plan))
        expect(flash[:notice]).to eq('New version published.')
        expect(plan.snapshots.order(:version).last.visibility).to eq('privately_visible')
      end
    end

    context 'when unauthorized' do
      it 'does not create a snapshot' do
        expect { subject }.not_to change(plan.snapshots, :count)

        expect(response).to redirect_to(plans_url)
      end
    end
  end
end
