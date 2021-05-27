# frozen_string_literal: true

# @abstract Builds a search query of all resources the user has edit access to. This is used to power the dashboard
# search interface. Draft, embargoed, and withdrawn works are eligible if the user has edit access to them.

module Dashboard
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
    include CatalogSearchBehavior

    self.default_processor_chain += %i(
      search_related_files
      restrict_search_to_works_and_collections
      apply_gated_edit
      log_solr_parameters
    )
  end
end
