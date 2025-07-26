class Api::BloodWorkRequestsController < ApplicationController
  include Authenticable
  before_action :set_blood_work_request, only: [:cancel]

  def create
    authorize ExamRequest, :create?

    @patient = find_patient_by_id(blood_work_request_params[:patient_id])
    return render_not_found('Patient not found') unless @patient

    @exam_type = ExamType.find_by(id: blood_work_request_params[:exam_type_id])
    return render_not_found('Exam type not found') unless @exam_type

    @blood_work_request = ExamRequest.new(blood_work_request_params)
    @blood_work_request.doctor = current_user
    @blood_work_request.patient = @patient
    @blood_work_request.exam_type = @exam_type
    @blood_work_request.status = 'scheduled'

    if @blood_work_request.save
      render 'api/blood_work_requests/create', status: :created
    else
      render json: {
        error: 'Failed to create blood work request',
        errors: @blood_work_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def cancel
    # Primeiro verificar autorização básica
    authorize @blood_work_request, :cancel?

    # Depois verificar regras de negócio e retornar erros específicos
    if @blood_work_request.completed?
      return render json: {
        error: 'Cannot cancel completed blood work request'
      }, status: :forbidden
    end

    # Verificar regra específica para pacientes (3 horas antes)
    if current_user.patient? && current_user == @blood_work_request.patient
      unless current_user.can_cancel_exam_request?(@blood_work_request)
        return render json: {
          error: 'Cannot cancel this request. You can only cancel up to 3 hours before the scheduled time.'
        }, status: :unprocessable_entity
      end
    end

    if @blood_work_request.update(status: 'cancelled')
      render 'api/blood_work_requests/cancel'
    else
      render json: {
        error: 'Failed to cancel blood work request',
        errors: @blood_work_request.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def index
    authorize ExamRequest, :blood_work_requests?

    @requests = policy_scope(ExamRequest).includes(:patient, :doctor, :exam_type, :exam_result)
                      .order(scheduled_date: :desc)

    # Filtros opcionais
    @requests = @requests.where(status: params[:status]) if params[:status].present?
    @requests = @requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    @requests = @requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    # Paginação simples
    @limit = [params[:limit].to_i, 100].min
    @limit = 20 if @limit <= 0
    @offset = [params[:offset].to_i, 0].max
    @total = policy_scope(ExamRequest).count

    @requests = @requests.limit(@limit).offset(@offset)

    render 'api/blood_work_requests/index'
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

  def blood_work_request_params
    params.require(:blood_work_request).permit(
      :patient_id,
      :exam_type_id,
      :scheduled_date,
      :notes
    )
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end
end
