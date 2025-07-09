class Api::Admin::BaseController < ApplicationController
  include Authenticable
  before_action :ensure_admin_role

  private

  def ensure_admin_role
    render_forbidden unless current_user.admin?
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
