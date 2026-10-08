# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DoorkeeperApiHelper, type: :helper do
  describe 'API version constants and metadata' do
    it 'exposes the shared API names used across the form and auth logic' do
      expect(described_class::V2).to eq('v2')
      expect(described_class::COMMON_MADMP).to eq('common_madmp')
      expect(described_class::API_DEFAULT_SCOPES).to eq(
        'v2' => 'v2_read',
        'common_madmp' => 'common_madmp_read'
      )
    end
  end

  describe '#api_scope_options_for' do
    it 'returns the configured scope options for each API version' do
      expect(helper.api_scope_options_for('v2')).to eq(
        'Read' => 'v2_read',
        'Read + write' => 'v2_read v2_write'
      )

      expect(helper.api_scope_options_for('common_madmp')).to eq(
        'Read' => 'common_madmp_read',
        'Read + write' => 'common_madmp_read common_madmp_write'
      )
    end
  end

  describe '#api_version_label' do
    it 'labels the API versions for the form' do
      expect(helper.api_version_label('v2')).to eq('v2')
      expect(helper.api_version_label('common_madmp')).to eq('Common MaDMP')
    end
  end

  describe '#api_default_scope_for' do
    it 'returns the default read scope for each API version' do
      expect(helper.api_default_scope_for('v2')).to eq('v2_read')
      expect(helper.api_default_scope_for('common_madmp')).to eq('common_madmp_read')
    end
  end

  describe '#application_api_selection' do
    it 'returns the selected API version and combined scope from the application object' do
      application = Doorkeeper::Application.new(scopes: 'v2_read v2_write')

      expect(helper.application_api_selection(application)).to eq(
        api_version: 'v2',
        scope: 'v2_read v2_write'
      )
    end
  end

  describe '#selected_api_for' do
    it 'picks Common MaDMP when a common_madmp scope is present' do
      expect(helper.selected_api_for(['common_madmp_read'])).to eq('common_madmp')
    end

    it 'defaults to v2 for v2 scopes' do
      expect(helper.selected_api_for(['v2_read'])).to eq('v2')
      expect(helper.selected_api_for(['v2_write'])).to eq('v2')
    end
  end

  describe '#selected_scope_for' do
    it 'prefers the combined read and write scope when both v2 scopes are present' do
      expect(helper.selected_scope_for(%w[v2_read v2_write], 'v2')).to eq('v2_read v2_write')
    end

    it 'normalizes write-only v2 access to the combined read + write scope' do
      expect(helper.selected_scope_for(['v2_write'], 'v2')).to eq('v2_read v2_write')
    end

    it 'applies the same read / write selection rules to Common MaDMP' do
      expect(helper.selected_scope_for(['common_madmp_read'], 'common_madmp')).to eq('common_madmp_read')
      expect(helper.selected_scope_for(['common_madmp_write'], 'common_madmp'))
        .to eq('common_madmp_read common_madmp_write')
    end

    it 'ignores scopes belonging to another API' do
      expect(helper.selected_scope_for(%w[v2_read v2_write], 'common_madmp')).to eq('common_madmp_read')
    end

    it 'uses the default read scope when the target API has no selected scope' do
      expect(helper.selected_scope_for([], 'v2')).to eq('v2_read')
      expect(helper.selected_scope_for([], 'common_madmp')).to eq('common_madmp_read')
    end
  end
end
