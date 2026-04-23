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

      def initialize(json:, client:, api_version: :v1)
        @json = json
        @client = client
        @api_version = api_version
        @dmp = extract_dmp(json)
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def call
        # Do a pass through the raw JSON and check to make sure all required fields
        # were present. If not, return the specific errors
        errs = handle_json_validation_errors
        return { errors: errs, status: :bad_request } if errs.any?

        # Convert the JSON into a Plan and it's associations
        plan = handle_deserialization
        return { errors: [INVALID_JSON_ERR], status: :bad_request } unless plan.present?

        # Try to determine the Plan's owner
        owner = handle_owner(plan: plan, json: @dmp.fetch(:contact, {}))

        # Try to determine the Plan's org
        errs = handle_plan_org(plan: plan, owner: owner)
        return errs if errs.present?

        # Validate the plan and it's associations and return errors with context
        # e.g. 'Contact affiliation name can't be blank' instead of 'name can't be blank'
        errs = handle_contextualized_errors(plan)

        # The resulting plan (our its associations were invalid)
        return { errors: errs, status: :bad_request } if errs.any?
        # Skip if this is an existing DMP
        return { errors: EXISTS_ERR, status: :bad_request } unless plan.new_record?

        # If we cannot save for some reason then return an error
        plan = handle_safe_save(plan)
        return { errors: SAVE_ERR, status: :internal_server_error } if plan.new_record?

        # Attach the Owner to the Plan and notify/invite as appropriate
        if v2_api?
          owner = notify_owner(owner: owner, plan: plan)
        elsif owner.is_a?(Contributor)
          owner = invite_contributor(contributor: owner)
        end
        plan.add_user!(owner.id, :creator)

        { plan: plan }
      rescue JSON::ParserError
        { errors: [INVALID_JSON_ERR], status: :bad_request }
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      private

      # Returns `dmp` based on the API version's JSON request body structure
      def extract_dmp(json)
        indifferent = json.with_indifferent_access
        return indifferent.fetch(:dmp, {}) if v2_api?

        indifferent.fetch(:items, []).first.fetch(:dmp, {})
      end

      def handle_deserialization
        service = v2_api? ? Api::V2::Deserialization::Plan : Api::V1::Deserialization::Plan
        service.deserialize(json: @dmp)
      end

      def handle_json_validation_errors
        service = v2_api? ? Api::V2::JsonValidationService : Api::V1::JsonValidationService
        service.validation_errors(json: @dmp)
      end

      def handle_contextualized_errors(plan)
        return Api::V2::ContextualErrorService.contextualize_errors(plan: plan) if v2_api?

        Api::V1::ContextualErrorService.process_plan_errors(plan: plan)
      end

      def handle_safe_save(plan)
        service = v2_api? ? Api::V2::PersistenceService : Api::V1::PersistenceService
        service.safe_save(plan: plan)
      end

      def handle_owner(plan:, json:)
        v2_api? ? determine_v2_owner(plan: plan, json: json) : determine_owner(plan: plan)
      end

      def handle_plan_org(plan:, owner:)
        if v2_api?
          plan.org_id = owner&.org&.present? ? owner.org_id : @client&.org_id
          if plan.org_id.blank?
            matches = find_matching_orgs(
              plan: plan, json: @dmp.fetch(:contact, {}).fetch(:affiliation, {})
            )
            no_org_err = format(no_org_err, list_of_names: matches.map { |m| "'#{m}'" }.join(', '))
            { errors: no_org_err, status: :bad_request }
          end
        else
          plan.org = owner.org if owner.present? && plan.org.blank?
          { errors: NO_ORG_ERR, status: :bad_request } unless plan.org.present?
        end
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

      def v2_api?
        @api_version == :v2
      end

      # Get the Plan's owner
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      def determine_v2_owner(plan:, json:)
        return nil unless plan.present? && json.is_a?(Hash) && json[:mbox].present?

        user = User.find_by(email: json[:mbox])
        return user if user.present?

        id_json = json.fetch(:contact_id, {})
        orcid = id_json[:identifier] if id_json[:type]&.downcase == 'orcid'
        identifier = Identifier.by_scheme_name('orcid', 'User').where(value: orcid) if orcid.present?
        return identifier.identifiable if identifier.present?

        names = json[:name]&.split || ['']
        firstname = names.length > 1 ? names.first : nil
        surname = names.length > 1 ? names.last : names.first

        # Try to deserialize the Org.
        org = Api::V2::Deserialization::Org.deserialize(json: json[:affiliation])
        org.save if org&.new_record?

        user = User.new(firstname: firstname, surname: surname, email: json[:mbox], org: org,
                        password: SecureRandom.uuid)
        return user if orcid.blank?

        scheme = IdentifierScheme.find_by(name: 'orcid')
        user.identifiers << Identifier.new(identifier_scheme: scheme, value: orcid)
        user
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

      # If the contact's org could not be determined, then fetch the matches to return to the
      # caller
      def find_matching_orgs(plan:, json:)
        return [] unless plan.present? && json.is_a?(Hash) && json[:name].present?

        name = json[:name].downcase.split('(').first
        matches = Org.where(managed: true).search(name)
        matches.any? ? matches.map(&:name) : []
      end

      # Send the owner an email to let them know about the new Plan
      def notify_owner(owner:, plan:)
        return unless owner.new_record?

        # This essentially drops the initializer User (aka owner) and creates a new one
        # via the Devise invitation methods
        User.invite!({ email: owner.email,
                       firstname: owner.firstname,
                       surname: owner.surname,
                       org: owner.org }, @client)

        # TODO: How to notify an existing user?
        # - DMP Assistant does not yet have UserMailer.new_plan_via_api()
        # else
        #   UserMailer.new_plan_via_api(
        #     recipient: owner, plan: plan, api_client: @client
        #   ).deliver_now
        #   owner
      end
    end
  end
end
