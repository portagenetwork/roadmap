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

        return render_error(errors: [_('Plan not found')], status: :not_found) unless plans_policy(@plan).show?

        @items = [@plan]
        @total_items = 1
        render '/api/v2/plans/index', status: :ok
      end

      # GET /api/v2/plans
      def index
        @plans = plans_scope
        @items = paginate_response(results: @plans)
        render '/api/v2/plans/index', status: :ok
      end

      # POST /api/v2/plans
      def create
        result = Api::Plans::CreateFromDmpService.new(json: @json, caller: @resource_owner, api_version: :v2).call

        if result[:plan].present?
          # Kaminari Pagination requires an ActiveRecord result set :/
          @items = paginate_response(results: plans_scope.where(id: result[:plan].id))
          render '/api/v2/plans/index', status: :created
        else
          render_error(errors: result[:errors], status: result[:status])
        end
      end

      # PUT api/v2/plans/:id
      def update # rubocop:disable Metrics/AbcSize
        plan = Plan.joins(:roles)
                   .where(roles: { user_id: @resource_owner.id, active: true })
                   .preload(:roles)
                   .find_by(id: params[:id])

        return render_error(errors: [_('Plan not found')], status: :not_found) unless plan

        raise Pundit::NotAuthorizedError unless plans_policy(plan).update?

        answers_payload = validate_answers_payload
        return if performed? # Halts execution if render_error was called

        payload_q_ids = answers_payload.map { |ans| ans[:question_id].to_i }

        # Check if there are any invalid questions first (Business logic validation)
        invalid_ids_msg = validate_questions(plan, payload_q_ids)
        return render_error(errors: [invalid_ids_msg], status: :bad_request) if invalid_ids_msg

        save_answers!(plan: plan, answers_payload: answers_payload, payload_q_ids: payload_q_ids)

        # Successful response
        @complete = true # enables response body to include updated answers
        @items = paginate_response(results: plans_scope.where(id: plan.id))
        render '/api/v2/plans/index', status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render_error(errors: e.record.errors.full_messages, status: :bad_request)
      end

      private

      def plans_policy(plan)
        PlansPolicy.new(@resource_owner, plan)
      end

      # GET /api/v2/plans?complete=true and  /api/v2/plans/:id?complete=true
      def set_complete_param
        @complete = params[:complete].to_s.casecmp('true').zero?
      end

      def plans_scope
        scope = PlansPolicy::Scope.new(@resource_owner).resolve
        @complete ? scope.includes(answers: { question: :section }) : scope
      end

      def validate_questions(plan, question_ids) # rubocop:disable Metrics/AbcSize
        # First check if there are any duplicate question IDs from the payload
        return _('Duplicate question ids found in payload') if question_ids.length != question_ids.uniq.length

        # Now check if questions belong to this plan's template
        questions = plan.template.questions.where(id: question_ids)
        missing_ids = question_ids - questions.pluck(:id)

        return _("Question(s) #{missing_ids.join(', ')} do not belong to this plan's template.") if missing_ids.any?

        # Now check if those (valid) questions have the correct format
        allowed_titles = ['Text area', 'Text field']
        allowed_format_ids = QuestionFormat.where(title: allowed_titles).pluck(:id)

        invalid_format_question_ids = questions.where.not(question_format_id: allowed_format_ids).pluck(:id)

        if invalid_format_question_ids.any?
          return _('Only plain text answers are currently allowed. Question(s) ' \
                   "#{invalid_format_question_ids.join(', ')} do not support that format.")
        end

        # Everything is valid
        nil
      end

      def validate_answers_payload
        payload = extract_answers_payload(@json)
        return payload if payload.present?

        render_error(
          errors: [
            _('Invalid or missing answers payload. Each answer must be an object with an integer question_id and ' \
              'value. Example: {"answers":[{"question_id":999,"value":"Updated answer."}]}')
          ],
          status: :bad_request
        )
      end

      def extract_answers_payload(json)
        payload = json.with_indifferent_access[:answers]
        return nil unless payload.is_a?(Array)

        is_valid = payload.all? do |ans|
          ans.is_a?(Hash) && ans.key?(:question_id) &&
            ans[:question_id].is_a?(Integer) &&
            ans.key?(:value)
        end

        is_valid ? payload : nil
      end

      def save_answers!(plan:, answers_payload:, payload_q_ids:)
        existing_answers = plan.answers.where(question_id: payload_q_ids).index_by(&:question_id)

        ActiveRecord::Base.transaction do
          answers_payload.each do |ans|
            question_id = ans[:question_id].to_i
            answer = existing_answers[question_id] || Answer.new(plan_id: plan.id, question_id: question_id)
            answer.update!(user_id: @resource_owner.id, text: ans[:value])
          end
        end
      end
    end
  end
end
