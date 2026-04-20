# frozen_string_literal: true

module Api
  module Plans
    # Service for creating a Plan from a DMP JSON payload (API v1 format).
    # Extracted to support reuse by future API versions.
    class CreateFromDmpService
      def initialize(json:, client:, api_version: :v1)
        @client = client
        @api_version = api_version
      end

      # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def call
        dmp = @json.with_indifferent_access.fetch(:items, []).first.fetch(:dmp, {})

        # Do a pass through the raw JSON and check to make sure all required fields
        # were present. If not, return the specific errors
        errs = Api::V1::JsonValidationService.validation_errors(json: dmp)
        return { errors: errs, status: :bad_request } if errs.any?

        # Convert the JSON into a Plan and it's associations
        plan = Api::V1::Deserialization::Plan.deserialize(json: dmp)
        if plan.present?
          save_err = _('Unable to create your DMP')
          exists_err = _('Plan already exists. Send an update instead.')
          no_org_err = _("Could not determine ownership of the DMP. Please add an
                          :affiliation to the :contact")

          # Try to determine the Plan's owner
          owner = determine_owner(plan: plan)
          plan.org = owner.org if owner.present? && plan.org.blank?
          return { errors: no_org_err, status: :bad_request } unless plan.org.present?

          # Validate the plan and it's associations and return errors with context
          # e.g. 'Contact affiliation name can't be blank' instead of 'name can't be blank'
          errs = Api::V1::ContextualErrorService.process_plan_errors(plan: plan)

          # The resulting plan (our its associations were invalid)
          return { errors: errs, status: :bad_request } if errs.any?
          # Skip if this is an existing DMP
          return { errors: exists_err, status: :bad_request } unless plan.new_record?

          # If we cannot save for some reason then return an error
          plan = Api::V1::PersistenceService.safe_save(plan: plan)
          return { errors: save_err, status: :internal_server_error } if plan.new_record?

          # Invite the Owner if they are a Contributor then attach the Owner to the Plan
          owner = invite_contributor(contributor: owner) if owner.is_a?(Contributor)
          plan.add_user!(owner.id, :creator)

          { plan: plan }
        else
          { errors: [_('Invalid JSON!')], status: :bad_request }
        end
      rescue JSON::ParserError
        { errors: [_('Invalid JSON')], status: :bad_request }
      end
      # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      # Get the Plan's owner
      def determine_owner(plan:)
        contact = plan.contributors.find(&:data_curation?)
        # Use the contact if it was sent in and has an affiliation defined
        return contact if contact.present? && contact.org.present?

        # If the contact has no affiliation defined, see if they are already a User
        user = lookup_user(contributor: contact)
        return user if user.present?

        # Otherwise just return the client
        @client
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
                              org: contributor.org }, @client)

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
