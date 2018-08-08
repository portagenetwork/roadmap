require 'rails_helper'

RSpec.describe Section, type: :model do

  context "validations" do
    it { is_expected.to validate_presence_of(:title) }

    it { is_expected.to validate_presence_of(:number) }

    it { is_expected.to validate_presence_of(:phase) }

    it { is_expected.to validate_uniqueness_of(:number)
                          .scoped_to(:phase_id)
                          .with_message("must be unique") }

    it { is_expected.to allow_values(true, false).for(:modifiable) }

  end

  context "associations" do

    it { is_expected.to belong_to :phase }

    it { is_expected.not_to belong_to :organisation }

    it { is_expected.to have_one :template }

    it { is_expected.to have_many :questions }

  end

  describe "#num_answered_questions" do

    let!(:phase) { create(:phase, template: template) }

    let!(:section) { create(:section, phase: phase) }

    subject { section.num_answered_questions(plan) }

    context "when plan is nil" do

      let!(:plan) { nil }

      let!(:template) { create(:template) }

      it { is_expected.to be_zero }

    end

    context "when plan is present" do

      let!(:plan) { create(:plan) }

      let!(:template) { plan.template }

      before do
        question = create(:question, section: section)
        create(:answer, question: question, plan: plan, text: '')

        question = create(:question, section: section)
        create(:answer, question: question, plan: plan)

        question = create(:question, section: section)
        create(:answer, question: question, plan: plan)
      end

      it "is expected to return the number of valid answered questions" do
        expect(subject).to eql(2)
      end

    end

  end

end
