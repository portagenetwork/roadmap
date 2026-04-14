# frozen_string_literal: true

module Api
  module V2
    class PlansController < BaseApiController # rubocop:todo Style/Documentation
      respond_to :json
      before_action :set_complete_param, only: %i[show index]

      # If the Resource Owner (aka User) is in the Doorkeeper AccessToken then it is an authorization_code
      # token and we need to ensure that the OAuth application is authorized for the relevant Scope
      before_action -> { doorkeeper_authorize! :write }, only: %i[create update]

      # GET /api/v2/plans/:id
      def show
        @plan = plans_scope.find_by(id: params[:id])

        plans_policy = PlansPolicy.new(@resource_owner, @plan)
        raise Pundit::NotAuthorizedError unless plans_policy.show?

        @items = [@plan]
        render '/api/v2/plans/index', status: :ok
      end

      # GET /api/v2/plans
      def index
        @plans = plans_scope
        @items = paginate_response(results: @plans)
        render '/api/v2/plans/index', status: :ok
      end

      # POST /api/v2/plans
      def create # rubocop:disable Metrics/AbcSize
        json = parsed_json
        return render_error(errors: [_('Invalid JSON')], status: :bad_request) if json.blank?

        result = Api::Plans::CreateFromDmpService.new(json: json, client: @resource_owner).call

        if result[:plan].present?
          # Kaminari Pagination requires an ActiveRecord result set :/
          @items = paginate_response(results: plans_scope.where(id: result[:plan].id))
          render '/api/v2/plans/index', status: :created
        else
          render_error(errors: result[:errors], status: result[:status])
        end
      end

      # PUT api/v2/plans/:id
      def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        json = parsed_json
        return render_error(errors: [_('Invalid JSON')], status: :bad_request) unless json

        plan = Plan.joins(:roles)
                   .where(roles: { user_id: @resource_owner.id, active: true })
                   .distinct
                   .find_by(id: params[:id])

        return render_error(errors: [_('Plan not found')], status: :not_found) unless plan

        plans_policy = PlansPolicy.new(@resource_owner, plan)
        raise Pundit::NotAuthorizedError unless plans_policy.update?

        answers_payload = json.with_indifferent_access[:answers]
        unless answers_payload.is_a?(Array)
          return render_error(errors: [_('Missing answers payload')], status: :bad_request)
        end

        payload_q_ids = answers_payload.map { |ans| ans[:question_id].to_i }.uniq

        # Check if there are any invalid questions first (Business logic validation)
        invalid_ids_msg = validate_questions(plan, payload_q_ids)
        return render_error(errors: [invalid_ids_msg], status: :bad_request) if invalid_ids_msg

        # Pre-fetch existing answers to avoid N+1 queries during the update loop
        existing_answers = plan.answers.where(question_id: payload_q_ids).index_by(&:question_id)

        begin
          ActiveRecord::Base.transaction do
            answers_payload.each do |ans|
              question_id = ans[:question_id].to_i

              # Find existing answer or initialize a new one
              answer = existing_answers[question_id] || Answer.new(plan_id: plan.id, question_id: question_id)

              # update! will raise ActiveRecord::RecordInvalid if it fails, triggering a rollback
              answer.update!(user_id: @resource_owner.id, text: ans[:text])
            end
          end
        rescue ActiveRecord::RecordInvalid => e
          # Catch the validation error, extract the messages, and return the 400
          return render_error(errors: e.record.errors.full_messages, status: :bad_request)
        end

        # Successful response
        @items = paginate_response(results: Plan.where(id: plan.id))
        render '/api/v2/plans/index', status: :ok
      end

      private

      # GET /api/v2/plans?complete=true and  /api/v2/plans/:id?complete=true
      def set_complete_param
        @complete = params[:complete].to_s.casecmp('true').zero?
      end

      def plans_scope
        scope = PlansPolicy::Scope.new(@resource_owner).resolve
        @complete ? scope.includes(answers: { question: :section }) : scope
      end

      def parsed_json
        @parsed_json ||= JSON.parse(request.body.read)
      rescue JSON::ParserError
        nil
      end

      def validate_questions(plan, question_ids)
        # DB query to see which of the payload_ids belong to this plan's template
        valid_ids = plan.template.questions.where(id: question_ids).pluck(:id)

        invalid_ids = question_ids - valid_ids
        return nil if invalid_ids.empty?

        _("Question(s) #{invalid_ids.join(', ')} do not belong to this plan's template")
      end
    end
  end
end
