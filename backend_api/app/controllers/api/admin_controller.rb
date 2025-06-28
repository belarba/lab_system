class Api::AdminController < ApplicationController
  include Authenticable
  before_action :ensure_admin_role
  before_action :set_user, only: [:show_user, :update_user, :destroy_user]

  # Users Management
  def users
    users = User.includes(:roles).order(:name)

    # Filtros
    users = users.joins(:roles).where(roles: { name: params[:role] }) if params[:role].present?
    users = users.where("name ILIKE ? OR email ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?

    # Paginação
    limit = [params[:limit].to_i, 100].min
    limit = 20 if limit <= 0
    offset = [params[:offset].to_i, 0].max

    users = users.limit(limit).offset(offset)

    render json: {
      users: users.map { |user| detailed_user_response(user) },
      pagination: {
        limit: limit,
        offset: offset,
        total: User.count
      }
    }, status: :ok
  end

  def show_user
    render json: {
      user: detailed_user_response(@user)
    }, status: :ok
  end

  def create_user
    user = User.new(user_params)
    user.password = params[:password] || 'defaultpassword123'
    user.password_confirmation = user.password

    if user.save
      # Atribuir roles
      if params[:role_ids].present?
        roles = Role.where(id: params[:role_ids])
        user.roles = roles
      end

      render json: {
        message: 'User created successfully',
        user: detailed_user_response(user)
      }, status: :created
    else
      render json: {
        error: 'Failed to create user',
        errors: user.errors.full_messages
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

      render json: {
        message: 'User updated successfully',
        user: detailed_user_response(@user)
      }, status: :ok
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
      render json: {
        message: 'User deleted successfully'
      }, status: :ok
    else
      render json: {
        error: 'Failed to delete user',
        errors: @user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # Exam Types Management
  def exam_types
    exam_types = ExamType.all.order(:name)

    render json: {
      exam_types: exam_types.map { |et| exam_type_response(et) }
    }, status: :ok
  end

  def create_exam_type
    exam_type = ExamType.new(exam_type_params)

    if exam_type.save
      render json: {
        message: 'Exam type created successfully',
        exam_type: exam_type_response(exam_type)
      }, status: :created
    else
      render json: {
        error: 'Failed to create exam type',
        errors: exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def update_exam_type
    exam_type = ExamType.find(params[:id])

    if exam_type.update(exam_type_params)
      render json: {
        message: 'Exam type updated successfully',
        exam_type: exam_type_response(exam_type)
      }, status: :ok
    else
      render json: {
        error: 'Failed to update exam type',
        errors: exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def destroy_exam_type
    exam_type = ExamType.find(params[:id])

    if exam_type.exam_requests.any?
      return render json: {
        error: 'Cannot delete exam type that has associated requests'
      }, status: :unprocessable_entity
    end

    if exam_type.destroy
      render json: {
        message: 'Exam type deleted successfully'
      }, status: :ok
    else
      render json: {
        error: 'Failed to delete exam type',
        errors: exam_type.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  # System Performance & Statistics
  def system_stats
    stats = {
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

    render json: {
      system_stats: stats,
      generated_at: Time.current
    }, status: :ok
  end

  def roles
    render json: {
      roles: Role.all.map { |role| role_response(role) }
    }, status: :ok
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

  def detailed_user_response(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      roles: user.roles.map { |role| role_response(role) },
      created_at: user.created_at,
      updated_at: user.updated_at,
      stats: {
        exam_requests_as_patient: user.patient_exam_requests.count,
        exam_requests_as_doctor: user.doctor_exam_requests.count,
        exam_results_as_lab_tech: user.lab_exam_results.count,
        uploads_count: user.respond_to?(:lab_file_uploads) ? user.lab_file_uploads.count : 0
      }
    }
  end

  def role_response(role)
    {
      id: role.id,
      name: role.name,
      description: role.description
    }
  end

  def exam_type_response(exam_type)
    {
      id: exam_type.id,
      name: exam_type.name,
      description: exam_type.description,
      unit: exam_type.unit,
      reference_range: exam_type.reference_range,
      created_at: exam_type.created_at,
      updated_at: exam_type.updated_at,
      requests_count: exam_type.exam_requests.count
    }
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
