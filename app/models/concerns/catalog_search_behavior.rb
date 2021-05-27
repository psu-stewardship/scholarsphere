# frozen_string_literal: true

module CatalogSearchBehavior
  extend ActiveSupport::Concern

  # @note This applies the lucene query parser because edismax doesn't seem to work with the Solr join
  def search_related_files(solr_parameters)
    return if blacklight_params[:q].blank? || blacklight_params[:search_field] != 'all_fields'

    user_query = blacklight_params[:q]
    solr_parameters[:q] = "{!lucene}#{dismax_query(user_query)} #{related_file_resources(user_query)}"
    solr_parameters[:defType] = 'lucene'
  end

  def restrict_search_to_works_and_collections(solr_parameters)
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '{!terms f=model_ssi}Work,Collection'
  end

  def log_solr_parameters(solr_parameters)
    Rails.logger.debug("Solr parameters: #{solr_parameters.inspect}")
  end

  def limit_to_public_resources(solr_parameters)
    return if current_user.admin?

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << '-embargoed_until_dtsi:[NOW TO *]'
    solr_parameters[:fq] << '-aasm_state_tesim:draft'
    solr_parameters[:fq] << '-aasm_state_tesim:withdrawn'
  end

  def apply_gated_edit(solr_parameters)
    return if current_user.admin?

    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << gated_edit_filters.compact.join(' OR ')
  end

  private

    def dismax_query(query_term)
      "{!dismax v=#{query_term}}"
    end

    def related_file_resources(query_term)
      "{!join from=id to=file_resource_ids_ssim}#{dismax_query(query_term)}"
    end

    def gated_edit_filters
      [
        :apply_group_permissions,
        :apply_user_permissions,
        :apply_depositor_access,
        :apply_proxy_access
      ].map do |method|
        send(method)
      end
    end

    # For groups
    # @return [String] a lucence syntax term query suitable for :fq
    # @example "({!terms f=edit_groups_ssim}public,faculty,africana-faculty,registered)"
    def apply_group_permissions
      groups = current_user.groups
      return if groups.empty?

      "({!terms f=edit_groups_ssim}#{groups.map(&:name).join(',')})"
    end

    # For individual user access
    # @return [String] a lucence syntax term query suitable for :fq
    # @example 'edit_access_person_ssim:user_1@abc.com'
    def apply_user_permissions
      escape_filter('edit_users_ssim', current_user.access_id)
    end

    def apply_depositor_access
      "{!terms f=depositor_id_isi}#{current_user.actor.id}"
    end

    def apply_proxy_access
      "{!terms f=proxy_id_isi}#{current_user.actor.id}"
    end

    def current_user
      @current_user ||= @scope.context[:current_user]
    end

    def escape_filter(key, value)
      [key, escape_value(value)].join(':')
    end

    def escape_value(value)
      RSolr.solr_escape(value).gsub(/ /, '\ ')
    end
end
