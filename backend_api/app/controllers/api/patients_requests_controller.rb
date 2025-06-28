class Api::PatientRequestsController < ApplicationController
  include Authenticable
  before_action :ensure_patient_role
  before_action :set_exam_request, only: [:cancel]

  def create
    exam_type = ExamType.find_by(id: params[:exam_type_id])
    return render_not_found('Exam type not found') unless exam_type

    # Verificar se pode solicitar (1 por semana do mesmo tipo)
    unless current_user.can_request_exam?(exam_type)
      return render json: {
        error: 'You can only request the same exam type once per week'
      }, status: :unprocessable_entity
    end

    # Encontrar um médico disponível (simplificado - pega o primeiro médico)
    doctor = User.joins(:roles).where(roles: { name: 'doctor' }).first
    unless doctor
      return render json: {
        error: 'No doctor available to process your request'
      }, status: :unprocessable_entity
    end

    exam_request = ExamRequest.new(
      patient: current_user,
      doctor: doctor,
      exam_type: exam_type,
      scheduled_date: params[:scheduled_date] || 1.week.from_now,
      status: 'pending',
      notes: params[:notes] || "Self-requested by patient"
    )

    if exam_request.save
      render json: {
        message: 'Blood work request created successfully',
        exam_request: exam_request_response(exam_request)
      }, status: :created
    else
      render json: {
        error: 'Failed to create blood work request',
        errors: exam_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def cancel
    unless current_user.can_cancel_exam_request?(@exam_request)
      return render json: {
        error: 'Cannot cancel this request. You can only cancel up to 3 hours before the scheduled time.'
      }, status: :unprocessable_entity
    end

    if @exam_request.update(status: 'cancelled')
      render json: {
        message: 'Blood work request cancelled successfully',
        exam_request: exam_request_response(@exam_request)
      }, status: :ok
    else
      render json: {
        error: 'Failed to cancel blood work request',
        errors: @exam_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def my_requests
    requests = current_user.patient_exam_requests
                          .includes(:doctor, :exam_type, :exam_result)
                          .order(scheduled_date: :desc)

    # Filtros opcionais
    requests = requests.where(status: params[:status]) if params[:status].present?
    requests = requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    requests = requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    # Paginação
    limit = [params[:limit].to_i, 50].min
    limit = 20 if limit <= 0
    offset = [params[:offset].to_i, 0].max

    requests = requests.limit(limit).offset(offset)

    render json: {
      exam_requests: requests.map { |request| exam_request_response(request) },
      pagination: {
        limit: limit,
        offset: offset,
        total: current_user.patient_exam_requests.count
      }
    }, status: :ok
  end

  private

  def ensure_patient_role
    render_forbidden unless current_user.patient?
  end

  def set_exam_request
    @exam_request = current_user.patient_exam_requests.find_by(id: params[:id])
    return render_not_found('Exam request not found') unless @exam_request
  end

  def exam_request_response(request)
    {
      id: request.id,
      doctor: {
        id: request.doctor.id,
        name: request.doctor.name,
        email: request.doctor.email
      },
      exam_type: {
        id: request.exam_type.id,
        name: request.exam_type.name,
        unit: request.exam_type.unit,
        reference_range: request.exam_type.reference_range
      },
      scheduled_date: request.scheduled_date,
      status: request.status,
      notes: request.notes,
      can_cancel: current_user.can_cancel_exam_request?(request),
      result: request.exam_result ? exam_result_response(request.exam_result) : nil,
      created_at: request.created_at,
      updated_at: request.updated_at
    }
  end

  def exam_result_response(result)
    {
      id: result.id,
      value: result.value,
      unit: result.unit,
      performed_at: result.performed_at,
      lab_technician: {
        id: result.lab_technician.id,
        name: result.lab_technician.name
      },
      notes: result.notes
    }
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
