# frozen_string_literal: true

require 'cgi'
require 'rails_helper'

RSpec.describe Api::Plans::CreateFromDmpService do
  include Webmocks
  include Mocks::ApiJsonSamples

  shared_examples 'returns a persisted plan' do
    it 'returns a plan if the incoming JSON is valid' do
      result = described_class.new(json: @json, caller: @client).call

      expect(result[:status]).to eql(nil)
      expect(result[:plan].present?).to eql(true)
      expect(result[:plan].persisted?).to eql(true)
    end
  end

  before(:each) do
    # Org model requires a language so make sure the default is set
    create(:language, abbreviation: 'test-lang', default_language: true) unless Language.default.present?

    stub_ror_service
    mock_identifier_schemes
    create(:template, :publicly_visible, is_default: true, published: true)

    # Service-level spec: provide a client context directly.
    # Auth is enforced by controllers
    # - v1 passes an ApiClient
    # - v2 derives client context from Doorkeeper
    @client = create(:api_client)
  end

  describe '#call' do
    context 'minimal JSON' do
      before(:each) do
        @json = JSON.parse(minimal_create_json).with_indifferent_access
      end

      it_behaves_like 'returns a persisted plan'

      it 'returns a 400 if the incoming DMP is invalid' do
        create(:plan)
        @json[:items].first[:dmp][:title] = ''

        result = described_class.new(json: @json, caller: @client).call

        expect(result[:plan]).to eql(nil)
        expect(result[:status]).to eql(:bad_request)
      end

      it 'returns a 400 if the plan already exists' do
        plan = create(:plan, created_at: (Time.now - 3.days))
        @json[:items].first[:dmp][:dmp_id] = {
          type: 'url',
          # Keep this URL generic so this shared service spec is not tied to a specific API version.
          identifier: Rails.application.routes.url_helpers.plan_url(plan)
        }

        result = described_class.new(json: @json, caller: @client).call

        expect(result[:plan]).to eql(nil)
        expect(result[:status]).to eql(:bad_request)
        expect(result[:errors].to_s.include?('already exists')).to eql(true)
      end

      it 'returns a 400 if the owner could not be determined' do
        @json[:items].first[:dmp][:contact].delete(:affiliation)

        result = described_class.new(json: @json, caller: @client).call

        expect(result[:plan]).to eql(nil)
        expect(result[:status]).to eql(:bad_request)
        expect(result[:errors].to_s.include?('Could not determine ownership')).to eql(true)
      end

      it 'defaults to client.org when no Contact affiliation defined' do
        @client.update(org: create(:org))
        @json[:items].first[:dmp][:contact].delete(:affiliation)

        result = described_class.new(json: @json, caller: @client).call

        expect(result[:plan].present?).to eql(true)
        expect(result[:plan].org).to eql(@client.org)
      end

      context 'plan inspection' do
        before(:each) do
          result = described_class.new(json: @json, caller: @client).call
          @original = @json.with_indifferent_access[:items].first[:dmp]
          @plan = result[:plan]
        end

        it 'set the Plan title' do
          expect(@plan.title).to eql(@original[:title])
        end
        it 'attached the contact to the Plan' do
          expect(@plan.contributors.length).to eql(1)
        end
        it 'set the Contact email' do
          expected = @plan.contributors.first.email
          expect(expected).to eql(@original[:contact][:mbox])
        end
        it "attached the plan to the Contact's Org" do
          expect(CGI.unescapeHTML(@plan.org.name)).to eql(@original[:contact][:affiliation][:name])
        end
        it 'set the Contact roles' do
          expected = @plan.contributors.first
          expect(expected.data_curation?).to eql(true)
        end
        it 'set the Template id' do
          app = ApplicationService.application_name.split('-').first
          tmplt = @original[:extension].find { |i| i[app].present? }
          expected = tmplt[app][:template][:id]
          expect(@plan.template_id).to eql(expected)
        end
      end
    end

    context 'complete JSON' do
      before(:each) do
        @json = JSON.parse(complete_create_json).with_indifferent_access
      end

      it_behaves_like 'returns a persisted plan'

      context 'plan inspection' do
        before(:each) do
          result = described_class.new(json: @json, caller: @client).call
          @original = @json.with_indifferent_access[:items].first[:dmp]
          @plan = result[:plan]
        end

        it 'set the Plan title' do
          expect(@plan.title).to eql(@original[:title])
        end

        it 'set the Plan description' do
          expect(@plan.description).to eql(@original[:description])
        end
        it 'set the Plan start_date' do
          expected = Api::V1::DeserializationService.safe_date(
            value: @original[:project].first[:start]
          )
          expect(@plan.start_date).to eql(expected)
        end
        it 'set the Plan end_date' do
          expected = Api::V1::DeserializationService.safe_date(
            value: @original[:project].first[:end]
          )
          expect(@plan.end_date).to eql(expected)
        end
        it 'Plan identifiers includes the grant id' do
          expect(@plan.identifiers.length).to eql(1)
          expected = @original[:project].first[:funding].first[:grant_id][:type]
          expect('other').to eql(expected)

          expected = @original[:project].first[:funding].first[:grant_id][:identifier]
          expect(@plan.identifiers.first.value).to eql(expected)
        end

        context 'contact inspection' do
          before(:each) do
            @original = @original[:contact]
            contacts = @plan.contributors.select do |pc|
              pc.email == @original[:mbox]
            end
            @contact = contacts.first
          end

          it 'attached the Contact to the Plan' do
            expect(@contact.present?).to eql(true)
          end
          it 'set the Contact name' do
            expect(@contact.name).to eql(@original[:name])
          end
          it 'set the Contact email' do
            expect(@contact.email).to eql(@original[:mbox])
          end
          it 'set the Contact roles' do
            expect(@contact.data_curation?).to eql(true)
          end
          it 'Contact identifiers includes the orcid' do
            expect(@contact.identifiers.length).to eql(1)
            expected = @original[:contact_id][:type]
            expect(@contact.identifiers.first.identifier_scheme.name).to eql(expected)

            expected = @original[:contact_id][:identifier]
            rslt = @contact.identifiers.first.value
            expect(rslt.ends_with?(expected)).to eql(true)
          end
          it 'ignored the unknown identifier type' do
            results = @contact.identifiers.select do |i|
              i.value == @original[:contact_id]
            end
            expect(results.any?).to eql(false)
          end

          context 'contact org inspection' do
            before(:each) do
              @original = @original[:affiliation]
            end

            it 'attached the Org to the Contact' do
              expect(@contact.org.present?).to eql(true)
            end
            it 'sets the name' do
              expect(CGI.unescapeHTML(@contact.org.name)).to eql(@original[:name])
            end
            it 'sets the abbreviation' do
              expect(@contact.org.abbreviation).to eql(@original[:abbreviation])
            end
            it 'Org identifiers includes the affiation id' do
              expect(@contact.org.identifiers.length).to eql(1)
              expected = @original[:affiliation_id][:type]
              result = @contact.org.identifiers.first.identifier_scheme.name
              expect(result).to eql(expected)

              expected = @original[:affiliation_id][:identifier]
              rslt = @contact.org.identifiers.first.value
              expect(rslt.ends_with?(expected)).to eql(true)
            end
            it "is the same as the Plan's org" do
              expect(@plan.org).to eql(@contact.org)
            end
          end
        end

        context 'contributor inspection' do
          before(:each) do
            @original = @original[:contributor].first
            contributors = @plan.contributors.select do |contrib|
              contrib.email == @original[:mbox]
            end
            @subject = contributors.first
          end

          it 'attached the Contributor to the Plan' do
            expect(@subject.present?).to eql(true)
          end
          it 'set the Contributor name' do
            expect(@subject.name).to eql(@original[:name])
          end
          it 'set the Contributor email' do
            expect(@subject.email).to eql(@original[:mbox])
          end
          it 'set the Contributor roles' do
            expected = @original[:role].map do |role|
              Api::V1::DeserializationService.translate_role(role: role)
            end
            expected.each do |role|
              expect(@subject.send(:"#{role}?"))
                .to eql(true)
            end
          end
          it 'Contributor identifiers includes the orcid' do
            expect(@subject.identifiers.length).to eql(1)
            expected = @original[:contributor_id][:type]
            expect(@subject.identifiers.first.identifier_scheme.name).to eql(expected)

            expected = @original[:contributor_id][:identifier]
            rslt = @subject.identifiers.first.value
            expect(rslt.ends_with?(expected)).to eql(true)
          end

          context 'contributor org inspection' do
            before(:each) do
              @original = @original[:affiliation]
            end

            it 'attached the Org to the Contributor' do
              expect(@subject.org.present?).to eql(true)
            end
            it 'sets the name' do
              expect(CGI.unescapeHTML(@subject.org.name)).to eql(@original[:name])
            end
            it 'sets the abbreviation' do
              expect(@subject.org.abbreviation).to eql(@original[:abbreviation])
            end
            it 'Org identifiers includes the affiation id' do
              expect(@subject.org.identifiers.length).to eql(1)
              expected = @original[:affiliation_id][:type]
              expect('ror').to eql(expected)

              expected = @original[:affiliation_id][:identifier]
              rslt = @subject.org.identifiers.first.value
              expect(rslt.ends_with?(expected)).to eql(true)
            end
          end
        end

        context 'funder inspection' do
          before(:each) do
            @original = @original[:project].first[:funding].first
            @funder = @plan.funder
          end

          it 'attached the Funder to the Plan' do
            expect(@funder.present?).to eql(true)
          end
          it 'sets the name' do
            expect(@funder.name).to eql(@original[:name])
          end
          it 'Funder identifiers includes the funder_id id' do
            expect(@funder.identifiers.length).to eql(1)
            expected = @original[:funder_id][:type]
            expect(@funder.identifiers.first.identifier_scheme.name).to eql(expected)

            expected = @original[:funder_id][:identifier].to_s
            rslt = @funder.identifiers.first.value
            expect(rslt.ends_with?(expected)).to eql(true)
          end
        end

        it 'set the Template id' do
          app = ApplicationService.application_name.split('-').first
          tmplt = @original[:extension].find { |i| i[app].present? }
          expected = tmplt[app][:template][:id]
          expect(@plan.template_id).to eql(expected)
        end
      end
    end
  end
end
