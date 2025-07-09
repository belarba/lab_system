class Api::AdminController < ApplicationController
  include Authenticable
  before_action :ensure_admin_role
  before_action :set_user, only: [:show_user, :update_user, :destroy_user]

  # Users Management
  def users
    @users = User.includes(:roles).order(:name)

    # Filtros
    @users = @users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?
    @users = @users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    # Paginação
    @limit = [params[:limit].to_i, 100].min
    @limit = 20 if @limit <= 0
    @offset = [params[:offset].to_i, 0].max
    @total = User.count

    @users = @users.limit(@limit).offset(@offset)

    render 'api/admin/users'
  end

  def show_user
    render 'api/admin/show_user'
  end

  def create_user
    @user = User.new(user_params)
    @user.password = params[:password] || 'defaultpassword123'
    @user.password_confirmation = @user.password

    if @user.save
      # Atribuir roles
      if params[:role_ids].present?
        roles = Role.where(id: params[:role_ids])
        @user.roles = roles
      end

      render 'api/admin/create_user', status: :created
    else
      render json: {
        error: 'Failed to create user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update_user
    if @user.update(user_params)
      # Atualizar roles se fornecido
      if params[:role_ids].present?
        roles = Role.where(id: params[:role_ids])
        @user.roles = roles
      end

      render 'api/admin/update_user'
    else
      render json: {
        error: 'Failed to update user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy_user
    if @user == current_user
      return render json: {
        error: 'You cannot delete your own account'
      }, status: :unprocessable_entity
    end

    if @user.destroy
      render 'api/admin/destroy_user'
    else
      render json: {
        error: 'Failed to delete user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Exam Types Management
  def exam_types
    @exam_types = ExamType.all.order(:name)
    render 'api/admin/exam_types'
  end

  def create_exam_type
    @exam_type = ExamType.new(exam_type_params)

    if @exam_type.save
      render 'api/admin/create_exam_type', status: :created
    else
      render json: {
        error: 'Failed to create exam type',
        errors: @exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update_exam_type
    @exam_type = ExamType.find(params[:id])

    if @exam_type.update(exam_type_params)
      render 'api/admin/update_exam_type'
    else
      render json: {
        error: 'Failed to update exam type',
        errors: @exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy_exam_type
    @exam_type = ExamType.find(params[:id])

    if @exam_type.exam_requests.any?
      return render json: {
        error: 'Cannot delete exam type that has associated requests'
      }, status: :unprocessable_entity
    end

    if @exam_type.destroy
      render 'api/admin/destroy_exam_type'
    else
      render json: {
        error: 'Failed to delete exam type',
        errors: @exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # System Performance & Statistics
  def system_stats
    @stats = {
      users: {
        total: User.count,
        patients: User.joins(:roles).where(roles: { name: 'patient' }).count,
        doctors: User.joins(:roles).where(roles: { name: 'doctor' }).count,
        lab_technicians: User.joins(:roles).where(roles: { name: 'lab_technician' }).count,
        admins: User.joins(:roles).where(roles: { name: 'admin' }).count
      },
      exam_requests: {
        total: ExamRequest.count,
        pending: ExamRequest.where(status: 'pending').count,
        scheduled: ExamRequest.where(status: 'scheduled').count,
        completed: ExamRequest.where(status: 'completed').count,
        cancelled: ExamRequest.where(status: 'cancelled').count
      },
      exam_results: {
        total: ExamResult.count,
        last_week: ExamResult.where(performed_at: 1.week.ago..Time.current).count,
        last_month: ExamResult.where(performed_at: 1.month.ago..Time.current).count
      },
      uploads: {
        total: LabFileUpload.count,
        completed: LabFileUpload.where(status: 'completed').count,
        failed: LabFileUpload.where(status: 'failed').count,
        processing: LabFileUpload.where(status: 'processing').count
      },
      exam_types: {
        total: ExamType.count,
        most_requested: most_requested_exam_types
      }
    }

    render 'api/admin/system_stats'
  end

  def roles
    @roles = Role.all
    render 'api/admin/roles'
  end

  private

  def ensure_admin_role
    render_forbidden unless current_user.admin?
  end

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_not_found('User not found')
  end

  def user_params
    params.require(:user).permit(:name, :email, :phone)
  end

  def exam_type_params
    params.require(:exam_type).permit(:name, :description, :unit, :reference_range)
  end

  def most_requested_exam_types
    ExamType.joins(:exam_requests)
            .group('exam_types.id', 'exam_types.name')
            .order('count_exam_requests_id DESC')
            .limit(5)
            .count('exam_requests.id')
            .map { |k, v| { name: k.last, count: v } }
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
