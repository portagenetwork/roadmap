# frozen_string_literal: true

# == Schema Information
#
# Table name: oauth_applications
#
# id:                 :integer
# name:               :string 
# uid:                :string 
# secret:             :string 
# redirect_uri:       :text 
# scopes:             :string
# confidential:       :boolean 
# created_at:         :datetime 
# updated_at:         :datetime

class OauthApplication < ApplicationRecord

end