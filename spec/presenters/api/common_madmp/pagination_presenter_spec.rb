# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::CommonMadmp::PaginationPresenter do
  describe '#prev_offset?' do
    it 'returns false when the offset is zero' do
      presenter = described_class.new(current_url: '/dmps', count: 10, total_count: 25, offset: 0)

      expect(presenter.prev_offset?).to be(false)
    end

    it 'returns true when the offset is greater than zero' do
      presenter = described_class.new(current_url: '/dmps', count: 10, total_count: 25, offset: 10)

      expect(presenter.prev_offset?).to be(true)
    end
  end

  describe '#next_offset?' do
    it 'returns false when total_count is blank' do
      presenter = described_class.new(current_url: '/dmps', count: 10, total_count: nil, offset: 0)

      expect(presenter.next_offset?).to be(false)
    end

    it 'returns false when no more results are available' do
      presenter = described_class.new(current_url: '/dmps', count: 10, total_count: 20, offset: 10)

      expect(presenter.next_offset?).to be(false)
    end

    it 'returns true when additional results remain' do
      presenter = described_class.new(current_url: '/dmps', count: 10, total_count: 25, offset: 10)

      expect(presenter.next_offset?).to be(true)
    end
  end

  describe '#url_without_pagination' do
    it 'returns nil when no URL is provided' do
      presenter = described_class.new(current_url: nil, count: 10, total_count: 25, offset: 0)

      expect(presenter.send(:url_without_pagination)).to be_nil
    end

    it 'removes offset and count params while preserving other query params' do
      url = 'https://example.org/dmps?other=true&offset=10&count=20'
      presenter = described_class.new(current_url: url, count: 20, total_count: 25, offset: 10)

      expect(presenter.send(:url_without_pagination)).to eq('https://example.org/dmps?other=true&')
    end

    it 'adds a trailing question mark when no query params remain' do
      url = 'https://example.org/dmps?offset=10&count=20'
      presenter = described_class.new(current_url: url, count: 20, total_count: 25, offset: 10)

      expect(presenter.send(:url_without_pagination)).to eq('https://example.org/dmps?')
    end
  end

  describe '#prev_page_link' do
    it 'returns the previous offset and keeps the same page size' do
      presenter = described_class.new(current_url: 'https://example.org/dmps?other=true', count: 10, total_count: 25,
                                      offset: 20)

      expect(presenter.prev_page_link).to eq('https://example.org/dmps?other=true&offset=10&count=10')
    end
  end

  describe '#next_page_link' do
    it 'returns the next offset and keeps the same page size' do
      presenter = described_class.new(current_url: 'https://example.org/dmps?other=true', count: 10, total_count: 25,
                                      offset: 10)

      expect(presenter.next_page_link).to eq('https://example.org/dmps?other=true&offset=20&count=10')
    end
  end
end
