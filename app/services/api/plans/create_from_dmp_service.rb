# frozen_string_literal: true

module Api
  module Plans
    # Service for creating a Plan from a DMP JSON payload (API v1 format).
    # Extracted to support reuse by future API versions.
    class CreateFromDmpService
      SAVE_ERR = _('Unable to create your DMP')
      EXISTS_ERR = _('Plan already exists. Send an update instead.')
      NO_ORG_ERR = _("Could not determine ownership of the DMP. Please add an
                          :affiliation to the :contact")
      INVALID_JSON_ERR = _('Invalid JSON')

      def initialize(json:, caller:, api_version: :v1)
        @json = json
        # NOTE: For v2, @caller is currently always a User.
        # - Revist this logic when v2 client credentials flow is implemented
        @caller = caller
        @api_version = api_version
        @dmp = extract_dmp(json)
        assign_services
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      def call
        # Do a pass through the raw JSON and check to make sure all required fields
        # were present. If not, return the specific errors
        errs = @json_validation_service.validation_errors(json: @dmp)
        return { errors: errs, status: :bad_request } if errs.any?

        # Convert the JSON into a Plan and its associations
        plan = @deserialize_plan_service.deserialize(json: @dmp)
        return { errors: [INVALID_JSON_ERR], status: :bad_request } unless plan.present?

        # For v2, always use @caller as owner; for v1, use legacy logic
        owner = v2_api? ? @caller : determine_owner(plan: plan)

        # Try to determine the Plan's org
        errs = handle_plan_org(plan: plan, owner: owner)
        return errs if errs.present?

        # Validate the plan and its associations and return errors with context
        # e.g. 'Contact affiliation name can't be blank' instead of 'name can't be blank'
        errs = handle_contextualized_errors(plan)

        # The resulting plan (or its associations) were invalid
        return { errors: errs, status: :bad_request } if errs.any?
        # Skip if this is an existing DMP
        return { errors: EXISTS_ERR, status: :bad_request } unless plan.new_record?

        # If we cannot save for some reason then return an error
        plan = @persistence_service.safe_save(plan: plan)
        return { errors: SAVE_ERR, status: :internal_server_error } if plan.new_record?

        # Attach the Owner to the Plan and notify/invite as appropriate
        attach_and_notify_owner(plan: plan, owner: owner)
        { plan: plan }
      rescue JSON::ParserError
        { errors: [INVALID_JSON_ERR], status: :bad_request }
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      private

      def v2_api?
        @api_version == :v2
      end

      # Returns `dmp` based on the API version's JSON request body structure
      def extract_dmp(json)
        indifferent = json.with_indifferent_access
        return indifferent.fetch(:dmp, {}) if v2_api?

        indifferent.fetch(:items, []).first.fetch(:dmp, {})
      end

      def assign_services
        api_module = v2_api? ? Api::V2 : Api::V1
        @json_validation_service   = api_module::JsonValidationService
        @deserialize_plan_service  = api_module::Deserialization::Plan
        @persistence_service       = api_module::PersistenceService
        @contextual_error_service  = api_module::ContextualErrorService
      end

      # Get the Plan's owner
      def determine_owner(plan:)
        contact = plan.contributors.find(&:data_curation?)
        # Use the contact if it was sent in and has an affiliation defined
        return contact if contact.present? && contact.org.present?

        # If the contact has no affiliation defined, see if they are already a User
        user = lookup_user(contributor: contact)
        return user if user.present?

        # Otherwise just return the client
        @caller
      end

      def lookup_user(contributor:)
        return nil unless contributor.present?

        identifiers = contributor.identifiers.map do |id|
          { name: id.identifier_scheme&.name, value: id.value }
        end
        user = User.from_identifiers(array: identifiers) if identifiers.any?
        user = User.find_by(email: contributor.email) unless user.present?
        user
      end

      def handle_plan_org(plan:, owner:)
        set_plan_org(plan: plan, owner: owner)
        # For v2, org is always @caller.org; for v1, check as before
        return if v2_api?

        { errors: NO_ORG_ERR, status: :bad_request } unless plan.org.present?
      end

      # If the contact's org could not be determined, then fetch the matches to return to the
      # caller
      def find_matching_orgs(plan:, json:)
        return [] unless plan.present? && json.is_a?(Hash) && json[:name].present?

        name = json[:name].downcase.split('(').first
        matches = Org.where(managed: true).search(name)
        matches.any? ? matches.map(&:name) : []
      end

      def set_plan_org(plan:, owner:)
        if v2_api?
          # For v2, owner is always @caller, so use @caller.org_id
          plan.org_id = @caller&.org_id
        elsif owner.present? && plan.org.blank?
          plan.org = owner.org
        end
      end

      def handle_contextualized_errors(plan)
        return @contextual_error_service.contextualize_errors(plan: plan) if v2_api?

        @contextual_error_service.process_plan_errors(plan: plan)
      end

      # Attach the owner to the plan and send notification if v2
      def attach_and_notify_owner(plan:, owner:)
        # For v2, @caller is always the owner and already a User
        owner = invite_contributor(contributor: owner) if !v2_api? && owner.is_a?(Contributor)
        plan.add_user!(owner.id, :creator)
      end

      # rubocop:disable Metrics/AbcSize
      def invite_contributor(contributor:)
        return nil unless contributor.present?

        # If the user was not found, invite them and attach any know identifiers
        names = contributor.name&.split || ['']
        firstname = names.length > 1 ? names.first : nil
        surname = names.length > 1 ? names.last : names.first
        user = User.invite!({ email: contributor.email,
                              firstname: firstname,
                              surname: surname,
                              org: contributor.org }, @caller)

        contributor.identifiers.each do |id|
          user.identifiers << Identifier.new(
            identifier_scheme: id.identifier_scheme, value: id.value
          )
        end
        user
      end
      # rubocop:enable Metrics/AbcSize
    end
  end
end
