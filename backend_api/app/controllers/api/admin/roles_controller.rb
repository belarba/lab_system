class Api::Admin::RolesController < Api::Admin::BaseController
  include Authenticable
  before_action :ensure_admin_role

  def index
    @roles = Role.all
  end

  private

  def ensure_admin_role
    render_forbidden unless current_user.admin?
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
