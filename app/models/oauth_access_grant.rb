# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_access_grants
#
# id:                 :integer
# resource_owner_id:  :integer
# application_id:     :integer
# token:              :string
# expires_in:         :integer
# redirect_uri:       :text
# scopes:             :string
# created_at:         :datetime
# revoked_at:         :datetime

class OauthAccessGrant < ApplicationRecord
end
