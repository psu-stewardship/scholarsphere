# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MemberFilesSchema, type: :schema do
  subject { described_class.new(resource: resource) }

  describe '#document' do
    context 'when the resource has files' do
      let(:resource) { create(:work_version, :with_files) }

      its(:document) do
        is_expected.to eq({
                            file_resource_ids_ssim: [resource.file_resources.first.uuid],
                            file_version_titles_ssim: [resource.file_version_memberships.first.title]
                          })
      end
    end

    context 'when the resource has NO files' do
      let(:resource) { create(:work_version) }

      its(:document) do
        is_expected.to eq({
                            file_resource_ids_ssim: [],
                            file_version_titles_ssim: []
                          })
      end
    end

    context 'with an unsupported resource' do
      let(:resource) { Struct.new('UnsupportedResource').new }

      its(:document) { is_expected.to be_empty }
    end
  end
end
