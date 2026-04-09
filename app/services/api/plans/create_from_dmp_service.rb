# frozen_string_literal: true

module Api
  module Plans
    class CreateFromDmpService # rubocop:disable Style/Documentation
      attr_reader :plan, :errors

      def initialize(json:, resource_owner:)
        @json = json.with_indifferent_access.fetch(:items, []).first.fetch(:dmp, {})
        @resource_owner = resource_owner
        @errors = []
        @plan = nil
      end

      def call # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
        return false unless valid_json_structure?

        # 1. Validate against JSON schema
        @errors = Api::V1::JsonValidationService.validation_errors(json: @json)
        return false if @errors.any?

        # 2. Deserialize JSON into a Plan object
        @plan = Api::V1::Deserialization::Plan.deserialize(json: @json)
        return false unless @plan.present?

        # 3. Handle Ownership and Org
        owner = determine_owner(client: @resource_owner, plan: @plan)
        @plan.org = owner.org if owner.present? && @plan.org.blank?

        if @plan.org.blank?
          @errors << 'Could not determine ownership of the DMP. Please add an :affiliation to the :contact'
          return false
        end

        # 4. Contextual Validation (e.g. check if associations are valid)
        @errors = Api::V1::ContextualErrorService.process_plan_errors(plan: @plan)
        return false if @errors.any?

        # 5. Check if it already exists
        unless @plan.new_record?
          @errors << 'Plan already exists. Send an update instead.'
          return false
        end

        # 6. Save and Post-Processing
        save_and_finalize(owner)
      end

      private

      def valid_json_structure?
        if @json.blank?
          @errors << 'Invalid JSON'
          return false
        end
        true
      end

      def save_and_finalize(owner)
        @plan = Api::V1::PersistenceService.safe_save(plan: @plan)
        if @plan.new_record?
          @errors << 'Unable to create your DMP'
          return false
        end

        # Associate with resource owner if applicable
        @plan.update(api_client_id: @resource_owner.id) if @resource_owner.is_a?(ApiClient)

        # Invite the owner if they are a new Contributor
        actual_owner = owner.is_a?(Contributor) ? invite_contributor(contributor: owner) : owner
        @plan.add_user!(actual_owner.id, :creator)
        true
      end

      def determine_owner(client:, plan:)
        contact = plan.contributors.find(&:data_curation?)
        # Use the contact if it was sent in and has an affiliation defined
        return contact if contact.present? && contact.org.present?

        # If the contact has no affiliation defined, see if they are already a User
        user = lookup_user(contributor: contact)
        return user if user.present?

        # Otherwise just return the client
        client
      end

      def lookup_user(contributor:)
        return nil unless contributor

        identifiers = contributor.identifiers.map do |id|
          { name: id.identifier_scheme&.name, value: id.value }
        end

        user = User.from_identifiers(array: identifiers) if identifiers.any?
        user ||= User.find_by(email: contributor.email)
        user
      end

      def invite_contributor(contributor:) # rubocop:disable Metrics/AbcSize
        return nil unless contributor.present?

        # If the user was not found, invite them and attach any know identifiers
        names = contributor.name&.split || ['']
        firstname = names.length > 1 ? names.first : nil
        surname = names.length > 1 ? names.last : names.first
        user = User.invite!({ email: contributor.email,
                              firstname: firstname,
                              surname: surname,
                              org: contributor.org }, @resource_owner)

        contributor.identifiers.each do |id|
          user.identifiers << Identifier.new(
            identifier_scheme: id.identifier_scheme, value: id.value
          )
        end
        user
      end
    end
  end
end
