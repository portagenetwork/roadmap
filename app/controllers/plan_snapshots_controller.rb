# frozen_string_literal: true

# Controller responsible for managing plan snapshots
class PlanSnapshotsController < ApplicationController
  include PdfExportable

  JSON_GENERATION_ERROR_ATTRIBUTES = %i[rda_json extension_json].freeze

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

  # GET /plans/:plan_id/versions/:version
  def show
    result = PlanSnapshots::FixityCheckService.new(@snapshot).call
    if result[:status] == :failed
      render json: {
        error: _('There was an error detected. The administrators of the repository have been alerted. ' \
                 'A check on (metadata/plan data) did not find matching checksums.')
      }, status: :unprocessable_entity
    else
      respond_to do |format|
        format.pdf  { show_pdf }
        format.any  { render json: @snapshot.rda_json }
      end
    end
  end

  # POST /plans/:plan_id/versions
  def create
    snapshot = create_snapshot_in_transaction

    if snapshot&.persisted?
      redirect_to plan_snapshots_path(@plan), notice: success_notice
    else
      redirect_to plan_snapshots_path(@plan), alert: create_failure_alert(snapshot)
    end
  rescue StandardError => e
    handle_doi_error(e)
  end

  private

  def create_snapshot_in_transaction
    ActiveRecord::Base.transaction do
      visibility = plan_snapshot_params[:visibility] || 'privately_visible'
      snapshot = PlanSnapshot.create_from_plan(plan: @plan, visibility: visibility)

      mint_doi_if_needed(snapshot)
      snapshot
    end
  end

  def mint_doi_if_needed(snapshot)
    return unless snapshot.persisted? && @plan.publicly_visible?

    ExternalApis::DoiPublisherService.publish_snapshot(snapshot)
  end

  def success_notice
    if @plan.publicly_visible?
      _('New version published and DOI minted.')
    else
      _('New version published.')
    end
  end

  def handle_doi_error(error)
    Rails.logger.error("Version publishing cancelled — DOI minting failed for Plan ##{@plan.id}: #{error.message}")
    redirect_to plan_snapshots_path(@plan),
                alert: _('Unable to publish version because DOI minting failed.')
  end

  def authorize_plan
    authorize @plan, policy_class: PlanSnapshotPolicy
  end

  def set_plan
    @plan = if action_name == 'create'
              Plan.for_snapshot_serialization(params[:plan_id])
            else
              Plan.find(params[:plan_id])
            end
  end

  def set_snapshot
    @snapshot = @plan.snapshots.find_by!(version: params[:version])
  end

  def plan_snapshot_params
    params.fetch(:plan_snapshot, {}).permit(:visibility)
  end

  def show_pdf
    @formatting = Settings::Template::DEFAULT_SETTINGS
    assign_contributors

    render pdf: file_name,
           template: 'shared/export/plan_snapshot',
           margin: @formatting[:margin],
           zoom: PDF_ZOOM,
           footer: pdf_footer(
             message: format(_('Created using %{application_name}. Version from %{date}'),
                             application_name: ApplicationService.application_name,
                             date: l(@snapshot.created_at.to_date, format: :readable))
           )
  end

  def assign_contributors
    @investigators = @snapshot.contributors.with_role(:investigation)
    @data_curators = @snapshot.contributors.with_role(:data_curation)
    @project_administrators = @snapshot.contributors.with_role(:project_administration)
    @other_contributors = @snapshot.contributors.with_role(:other)
  end

  def file_name
    sanitized_file_name(@snapshot.title, suffix: "_v#{@snapshot.version}")
  end

  def create_failure_alert(snapshot)
    if json_generation_failure?(snapshot)
      notify_json_generation_failure(snapshot)
      _('An error was detected and a new version cannot be published at this time. ' \
        'The administrators of the repository have been alerted.')
    else
      failure_message(snapshot, _('create'))
    end
  end

  def json_generation_failure?(snapshot)
    snapshot.errors.attribute_names.any? { |attr| JSON_GENERATION_ERROR_ATTRIBUTES.include?(attr.to_sym) }
  end

  def notify_json_generation_failure(snapshot)
    PlanSnapshots::FailureNotifier.call(
      message: PlanSnapshots::FailureNotifier::JSON_GENERATION_FAILURE_MESSAGE,
      payload: json_generation_alert_payload(snapshot)
    )
  end

  def json_generation_alert_payload(snapshot)
    {
      plan_id: @plan.id,
      user_id: current_user&.id,
      errors: snapshot.errors.to_hash(true)
    }
  end
end
