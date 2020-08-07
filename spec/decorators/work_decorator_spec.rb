# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkDecorator do
  it 'extends ResourceDecorator' do
    expect(described_class).to be < ResourceDecorator
  end

  describe '#versions' do
    subject(:decorator) { described_class.new(work) }

    let(:work) { create :work, versions_count: 2, has_draft: true }

    it 'creates version decorators with their indices' do
      allow(WorkVersionDecorator).to receive(:new)
      decorator.versions
      expect(WorkVersionDecorator).to have_received(:new).with(work.versions[0])
      expect(WorkVersionDecorator).to have_received(:new).with(work.versions[1])
    end
  end
end