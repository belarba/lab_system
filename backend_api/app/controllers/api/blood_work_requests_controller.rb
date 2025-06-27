class Api::BloodWorkRequestsController < ApplicationController
  include Authenticable
  before_action :set_blood_work_request, only: [:cancel]  # Remover :show

  def create
    # Apenas médicos podem criar requisições
    return render_forbidden unless current_user.doctor?

    # Verificar se o paciente existe e tem role de patient
    patient = find_patient_by_id(blood_work_request_params[:patient_id])
    return render_not_found('Patient not found') unless patient

    # Verificar se o tipo de exame existe
    exam_type = ExamType.find_by(id: blood_work_request_params[:exam_type_id])
    return render_not_found('Exam type not found') unless exam_type

    @blood_work_request = ExamRequest.new(blood_work_request_params)
    @blood_work_request.doctor = current_user
    @blood_work_request.patient = patient
    @blood_work_request.exam_type = exam_type
    @blood_work_request.status = 'scheduled'

    if @blood_work_request.save
      render json: {
        message: 'Blood work request created successfully',
        blood_work_request: exam_request_response(@blood_work_request)
      }, status: :created
    else
      render json: {
        error: 'Failed to create blood work request',
        errors: @blood_work_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def cancel
    # Verificar permissões para cancelar
    return render_forbidden unless can_cancel_request?(@blood_work_request)

    # Não pode cancelar se já foi realizado
    if @blood_work_request.completed?
      return render json: {
        error: 'Cannot cancel completed blood work request'
      }, status: :unprocessable_entity
    end

    if @blood_work_request.update(status: 'cancelled')
      render json: {
        message: 'Blood work request cancelled successfully',
        blood_work_request: exam_request_response(@blood_work_request)
      }, status: :ok
    else
      render json: {
        error: 'Failed to cancel blood work request',
        errors: @blood_work_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def index
    # Este endpoint pode ser usado para listar requisições gerais (admin/lab_tech)
    return render_forbidden unless current_user.admin? || current_user.lab_technician?

    requests = ExamRequest.includes(:patient, :doctor, :exam_type, :exam_result)
                         .order(scheduled_date: :desc)

    # Filtros opcionais
    requests = requests.where(status: params[:status]) if params[:status].present?
    requests = requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    requests = requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    # Paginação simples
    limit = [params[:limit].to_i, 100].min
    limit = 20 if limit <= 0
    offset = [params[:offset].to_i, 0].max

    requests = requests.limit(limit).offset(offset)

    render json: {
      blood_work_requests: requests.map { |request| exam_request_response(request) },
      pagination: {
        limit: limit,
        offset: offset,
        total: ExamRequest.count
      }
    }, status: :ok
  end

  private

  def set_blood_work_request
    @blood_work_request = ExamRequest.find_by(id: params[:id])
    return render_not_found('Blood work request not found') unless @blood_work_request
  end

  def find_patient_by_id(patient_id)
    User.joins(:roles)
        .where(roles: { name: 'patient' })
        .find_by(id: patient_id)
  end

  def can_cancel_request?(request)
    # Admin pode cancelar qualquer requisição
    # Médico pode cancelar suas próprias requisições
    # Paciente pode cancelar suas próprias requisições
    current_user.admin? ||
    current_user == request.doctor ||
    current_user == request.patient
  end

  def blood_work_request_params
    params.require(:blood_work_request).permit(
      :patient_id,
      :exam_type_id,
      :scheduled_date,
      :notes
    )
  end

  def exam_request_response(request)
    {
      id: request.id,
      patient: {
        id: request.patient.id,
        name: request.patient.name,
        email: request.patient.email
      },
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
