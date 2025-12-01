# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_access_tokens
#
# id:                     :integer
# resource_owner_id:      :integer
# application_id:         :integer
# token:                  :string
# refresh_token:          :string
# expires_in:             :integer
# scopes:                 :string
# created_at:             :datetime
# revoked_at:             :datetime
# previous_refresh_token: :string

class OauthAccessToken < ApplicationRecord
end
