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
      def create
        return render_error(errors: [_('Invalid JSON')], status: :bad_request) if parsed_json.blank?

        service = Api::Plans::CreateFromDmpService.new(
          json: parsed_json,
          resource_owner: @resource_owner
        )

        if service.call
          # Use the plan returned by the service for the response
          @items = paginate_response(results: Plan.where(id: service.plan.id))
          render '/api/v2/plans/index', status: :created
        else
          render_error(errors: service.errors, status: :bad_request)
        end
      rescue JSON::ParserError
        render_error(errors: [_('Invalid JSON')], status: :bad_request)
      end

      # PUT api/v2/plans/:id
      def update # rubocop:disable Metrics/AbcSize, Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        json = parsed_json
        return render_error(errors: ['Invalid JSON'], status: :bad_request) unless json

        plan = plans_scope.find_by(id: params[:id])
        return render_error(errors: ['Plan not found'], status: :not_found) unless plan

        plans_policy = PlansPolicy.new(@resource_owner, plan)
        raise Pundit::NotAuthorizedError unless plans_policy.update?

        answers_payload = json.with_indifferent_access[:answers]
        unless answers_payload.is_a?(Array)
          return render_error(errors: ['Missing answers payload'],
                              status: :bad_request)
        end

        # Gather all IDs from the payload
        question_ids = answers_payload.map { |ans| ans[:question_id].to_i }.uniq

        # Fetch only questions and answers that belong to the plan's template
        valid_question_ids = plan.template.questions.where(id: question_ids).index_by(&:id)
        existing_answers = plan.answers.where(question_id: question_ids).index_by(&:question_id)

        errors = []

        answers_payload.each do |ans|
          question_id = ans[:question_id].to_i

          # Validation: Does the question belong to this template?
          unless valid_question_ids.key?(question_id)
            errors << "Question #{question_id} does not belong to this plan"
            next
          end

          # Find existing answer from pre-fetched hash or initialize a new one
          answer = existing_answers[question_id] || Answer.new(plan_id: plan.id, question_id: question_id)
          # This ensures "User must exist" validation passes
          answer.user_id = @resource_owner.id
          answer.text = ans[:text]

          errors.concat(answer.errors.full_messages) unless answer.save
        end

        return render_error(errors: errors, status: :bad_request) if errors.any?

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
    end
  end
end
