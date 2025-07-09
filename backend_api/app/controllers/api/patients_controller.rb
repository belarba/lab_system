class Api::PatientsController < ApplicationController
  include Authenticable

  def show
    @patient = find_patient
    return render_not_found('Patient not found') unless @patient

    # Verificar se o usuário atual pode ver este paciente
    return render_forbidden unless can_view_patient?(@patient)

    render 'api/patients/show'
  end

  def blood_work_requests
    @patient = find_patient
    return render_not_found('Patient not found') unless @patient

    # Verificar se o usuário atual pode ver as requisições deste paciente
    return render_forbidden unless can_view_patient_requests?(@patient)

    @requests = @patient.patient_exam_requests
                       .includes(:doctor, :exam_type, :exam_result)
                       .order(scheduled_date: :desc)

    # Filtros avançados
    @requests = @requests.where(status: params[:status]) if params[:status].present?
    @requests = @requests.joins(:exam_type).where(exam_types: { id: params[:exam_type_id] }) if params[:exam_type_id].present?
    @requests = @requests.joins(:doctor).where(users: { id: params[:doctor_id] }) if params[:doctor_id].present?
    @requests = @requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    @requests = @requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    # Paginação
    @limit = [params[:limit].to_i, 50].min
    @limit = 20 if @limit <= 0
    @offset = [params[:offset].to_i, 0].max
    @total = @patient.patient_exam_requests.count

    @requests = @requests.limit(@limit).offset(@offset)

    render 'api/patients/blood_work_requests'
  end

  def test_results
    @patient = find_patient
    return render_not_found('Patient not found') unless @patient

    # Verificar se o usuário atual pode ver os resultados deste paciente
    return render_forbidden unless can_view_patient_results?(@patient)

    # Buscar resultados com filtros opcionais
    @results_query = ExamResult.joins(exam_request: :patient)
                              .where(exam_requests: { patient: @patient })
                              .includes(exam_request: [:exam_type, :doctor], lab_technician: [])
                              .order(performed_at: :desc)

    # Aplicar filtros
    apply_result_filters

    # Paginação
    @limit = [params[:limit].to_i, 50].min
    @limit = 20 if @limit <= 0
    @offset = [params[:offset].to_i, 0].max

    @results = @results_query.limit(@limit).offset(@offset)
    @total = @results_query.count

    # Preparar dados para trends e summary
    prepare_trends_and_summary

    render 'api/patients/test_results'
  end

  private

  def find_patient
    patient_id = params[:id] || params[:patient_id]

    patient = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .find_by(id: patient_id)

    patient
  end

  def can_view_patient?(patient)
    # Admin pode ver tudo, paciente pode ver próprio perfil, médico pode ver seus pacientes
    current_user.admin? ||
    current_user == patient ||
    (current_user.doctor? && current_user.doctor_patients.include?(patient))
  end

  def can_view_patient_requests?(patient)
    can_view_patient?(patient)
  end

  def can_view_patient_results?(patient)
    # Admin pode ver tudo, paciente pode ver próprios resultados, médico pode ver de seus pacientes, lab_tech pode ver todos
    current_user.admin? ||
    current_user == patient ||
    current_user.lab_technician? ||
    (current_user.doctor? && current_user.doctor_patients.include?(patient))
  end

  def apply_result_filters
    # Filtros avançados
    if params[:exam_type_id].present?
      @results_query = @results_query.joins(exam_request: :exam_type)
                                     .where(exam_requests: { exam_type_id: params[:exam_type_id] })
    end

    if params[:doctor_id].present?
      @results_query = @results_query.joins(exam_request: :doctor)
                                     .where(exam_requests: { doctor_id: params[:doctor_id] })
    end

    # Filtrar por data se especificado
    if params[:from_date].present?
      @results_query = @results_query.where('exam_results.performed_at >= ?', params[:from_date])
    end

    if params[:to_date].present?
      @results_query = @results_query.where('exam_results.performed_at <= ?', params[:to_date])
    end
  end

  def prepare_trends_and_summary
    # Agrupar por tipo de exame para trends (limitando para performance)
    all_results = @results_query.limit(200)
    @results_by_type = all_results.group_by { |result| result.exam_request.exam_type }

    # Summary data
    @summary_data = {
      total_results: all_results.length,
      normal_count: all_results.count { |r| helpers.determine_result_status(r.value, r.exam_request.exam_type) == 'normal' },
      high_count: all_results.count { |r| helpers.determine_result_status(r.value, r.exam_request.exam_type) == 'high' },
      low_count: all_results.count { |r| helpers.determine_result_status(r.value, r.exam_request.exam_type) == 'low' },
      date_range: {
        earliest: all_results.map(&:performed_at).min,
        latest: all_results.map(&:performed_at).max
      }
    }
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
