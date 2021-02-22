# frozen_string_literal: true

module Dashboard
  class CollectionsController < BaseController
    layout 'frontend'

    def edit
      @collection = Collection.find(params[:id])
      authorize(@collection)
      initialize_forms
    end

    def update
      @collection = Collection.find(params[:id])
      authorize(@collection)
      initialize_forms

      form = select_form_model

      if form.save
        redirect_to edit_dashboard_collection_path(@collection), notice: t('.success')
      else
        render :edit
      end
    end

    # DELETE /collections/1
    # DELETE /collections/1.json
    def destroy
      @collection = current_user.collections.find(params[:id])
      @collection.destroy
      respond_to do |format|
        format.html { redirect_to dashboard_root_path, notice: t('.success') }
        format.json { head :no_content }
      end
    end

    private

      def initialize_forms
        @collection.attributes = collection_params
        @editors_form = EditorsForm.new(resource: @collection, user: current_user, params: editors_params)
      end

      def select_form_model
        if params[:editors_form].present?
          @editors_form
        else
          @collection
        end
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def collection_params
        params
          .fetch(:collection, {})
          .permit(
            :visibility
          )
      end

      def editors_params
        params
          .fetch(:editors_form, {})
          .permit(
            edit_users: [],
            edit_groups: []
          )
      end
  end
end
