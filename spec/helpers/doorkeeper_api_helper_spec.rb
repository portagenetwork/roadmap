# spec/helpers/doorkeeper_scopes_helper_spec.rb
require 'rails_helper'

RSpec.describe DoorkeeperApiHelper, type: :helper do
  describe '#scope_options' do
    it 'offers read and read-and-write' do
      expect(helper.scope_options).to eq(
        'Read' => 'read',
        'Read and write' => 'read write'
      )
    end
  end

  describe '#scope_option_checked?' do
    def app_with(scopes)
      Doorkeeper::Application.new(scopes: scopes)
    end

    it 'selects "read" for a read-only application' do
      app = app_with('read')

      expect(helper.scope_option_checked?(app, 'read')).to be true
      expect(helper.scope_option_checked?(app, 'read write')).to be false
    end

    it 'selects "read write" for a read/write application' do
      app = app_with('read write')

      expect(helper.scope_option_checked?(app, 'read write')).to be true
      expect(helper.scope_option_checked?(app, 'read')).to be false
    end

    it 'ignores scope order' do
      app = app_with('write read')

      expect(helper.scope_option_checked?(app, 'read write')).to be true
    end

    it 'defaults to "read" when no scopes are set (new record)' do
      app = Doorkeeper::Application.new

      expect(helper.scope_option_checked?(app, 'read')).to be true
      expect(helper.scope_option_checked?(app, 'read write')).to be false
    end
  end
end
