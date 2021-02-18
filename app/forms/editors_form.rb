# frozen_string_literal: true

class EditorsForm
  include ActiveModel::Model

  attr_reader :resource, :user

  def initialize(resource:, params:, user:)
    @resource = resource
    @user = user
    super(params)
  end

  def edit_users
    @edit_users || resource.edit_users.map(&:access_id)
  end

  def edit_users=(access_ids)
    @edit_users = access_ids.reject(&:blank?)
  end

  def edit_groups
    @edit_groups || resource.edit_groups.map(&:name)
  end

  def edit_groups=(names)
    @edit_groups = names.reject(&:blank?)
  end

  def group_options
    (user.groups - User.default_groups).map(&:name)
  end

  def save
    user_list = build_users
    return false if errors.present?

    resource.edit_users = user_list
    resource.edit_groups = group_list
    resource.save
  end

  private

    def build_users
      edit_users.map do |access_id|
        service_wrapper(access_id) ||
          errors.add(:edit_users, I18n.t('dashboard.works.editors.not_found', access_id: access_id)) && access_id
      end
    end

    def group_list
      edit_groups.map do |name|
        Group.find_by(name: name)
      end.compact
    end

    # @note There are four outcomes from calling this wrapper:
    #   1) the call is successful and the user is found -> return the user's access id
    #   2) the call is successful and the user is NOT found -> return null
    #   3) the call is unsuccessful due to user error (URI::InvalidURIError) -> return the incorrect input
    #   4) the call is unsuccessful due to to some unknown reason -> raise the exeception
    def service_wrapper(access_id)
      UserRegistrationService.call(uid: access_id)
    rescue URI::InvalidURIError
      errors.add(:edit_users, I18n.t('dashboard.works.editors.unexpected', access_id: access_id)) && access_id
    end
end
