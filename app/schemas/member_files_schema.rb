# frozen_string_literal: true

class MemberFilesSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:file_resources)

    {
      file_resource_ids_ssim: file_uuids,
      file_version_titles_ssim: resource.file_version_memberships.pluck(:title)
    }
  end

  private

    # @note In the case where the file resources have just been created, we need to reload them from the database to the
    # get the generated UUIDs.
    def file_uuids
      uuids = resource.file_resources.pluck(:uuid)

      return uuids unless uuids.include?(nil)

      resource.file_resources.reload.pluck(:uuid)
    end
end
