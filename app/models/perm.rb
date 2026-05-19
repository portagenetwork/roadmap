# frozen_string_literal: true

# == Schema Information
#
# Table name: perms
#
#  id         :integer          not null, primary key
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

# Object that represents a User permission
class Perm < ApplicationRecord
  class << self
    private

    def lazy_load(name)
      Rails.cache
           .fetch("Perm.find_by_name(#{name})", expires_in: 5.seconds, cache_nils: false) do
             Perm.find_by_name(name)
           end
           .freeze
    end
  end

  # ================
  # = Associations =
  # ================

  has_and_belongs_to_many :users, join_table: :users_perms

  # ===============
  # = Validations =
  # ===============

  validates :name, presence: { message: PRESENCE_MESSAGE },
                   uniqueness: { message: UNIQUENESS_MESSAGE,
                                 case_sensitive: false }

  # =================
  # = Class methods =
  # =================

  def self.add_orgs
    lazy_load('add_organisations')
  end

  def self.change_affiliation
    lazy_load('change_org_affiliation')
  end

  def self.grant_permissions
    lazy_load('grant_permissions')
  end

  def self.modify_templates
    lazy_load('modify_templates')
  end

  def self.modify_guidance
    lazy_load('modify_guidance')
  end

  def self.use_api
    lazy_load('use_api')
  end

  def self.change_org_details
    lazy_load('change_org_details')
  end

  def self.grant_api
    lazy_load('grant_api_to_orgs')
  end

  def self.review_plans
    lazy_load('review_org_plans')
  end

  def self.manage_oauth_apps
    lazy_load('manage_oauth_apps')
  end

  def self.super_admin_names
    %w[add_organisations grant_api_to_orgs change_org_affiliation]
  end

  def self.org_admin_names(include_super_admin_names: true)
    names = %w[grant_permissions modify_templates modify_guidance change_org_details]
    names += super_admin_perm_names if include_super_admin_names
    names
  end
end
