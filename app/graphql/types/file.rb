# frozen_string_literal: true

module Types
  class File < Types::BaseObject
    field :filename, String, null: false
    field :mime_type, String, null: false
    field :size, GraphQL::Types::BigInt, null: false
    field :etag, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    def filename
      object.file_data.dig('metadata', 'filename')
    end

    def mime_type
      object.file_data.dig('metadata', 'mime_type')
    end

    def size
      object.file_data.dig('metadata', 'size')
    end
  end
end
