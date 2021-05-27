# frozen_string_literal: true

class RepresentativeVersionSchema < BaseSchema
  def document
    return {} unless resource.respond_to?(:representative_version)

    DefaultSchema.new(resource: resource.representative_version)
      .document
      .merge(creator_schema.document)
      .merge(published_date_schema.document)
      .merge(facet_schema.document)
      .merge(title_schema.document)
      .merge(member_files_schema.document)
  end

  private

    def creator_schema
      CreatorSchema.new(resource: resource.representative_version)
    end

    def published_date_schema
      PublishedDateSchema.new(resource: resource.representative_version)
    end

    def facet_schema
      FacetSchema.new(resource: resource.representative_version)
    end

    def title_schema
      TitleSchema.new(resource: resource.representative_version)
    end

    def member_files_schema
      MemberFilesSchema.new(resource: resource.representative_version)
    end
end
