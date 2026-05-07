# frozen_string_literal: true

# == Schema Information
#
# Table name: identifier_schemes
#
#  id                :integer          not null, primary key
#  active            :boolean
#  context           :integer
#  description       :string
#  identifier_prefix :text
#  logo_url          :text
#  name              :string
#  created_at        :datetime
#  updated_at        :datetime
#

FactoryBot.define do
  factory :identifier_scheme do
    name { Faker::Company.unique.name[0..29] }
    description { Faker::Movies::StarWars.quote }
    logo_url { Faker::Internet.url }
    identifier_prefix { "#{Faker::Internet.url}/" }
    active { true }

    transient do
      context_count { 1 }
    end

    after(:create) do |identifier_scheme, evaluator|
      (0..evaluator.context_count - 1).each do |idx|
        identifier_scheme.update("#{identifier_scheme.all_context[idx]}": true)
      end
    end

    trait :openid_connect do
      name { 'openid_connect' }
      description { 'CILogon' }
      identifier_prefix { 'https://www.cilogon.org/' }
    end

    %i[
      authentication
      orgs
      plans
      users
      contributors
      identification
      research_outputs
    ].each do |context|
      trait :"for_#{context}" do
        add_attribute(:"for_#{context}") { true }
      end
    end
  end
end
