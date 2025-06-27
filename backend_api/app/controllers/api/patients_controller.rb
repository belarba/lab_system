class Api::PatientsController < ApplicationController
  include Authenticable

  def show
    patient = find_patient
    return render_not_found('Patient not found') unless patient

    # Verificar se o usuário atual pode ver este paciente
    return render_forbidden unless can_view_patient?(patient)

    render json: {
      patient: detailed_patient_response(patient)
    }, status: :ok
  end

  def blood_work_requests
    patient = find_patient
    return render_not_found('Patient not found') unless patient

    # Verificar se o usuário atual pode ver as requisições deste paciente
    return render_forbidden unless can_view_patient_requests?(patient)

    requests = patient.patient_exam_requests
                     .includes(:doctor, :exam_type, :exam_result)
                     .order(scheduled_date: :desc)

    render json: {
      patient: user_response(patient),
      blood_work_requests: requests.map { |request| exam_request_response(request) }
    }, status: :ok
  end

  def test_results
    patient = find_patient
    return render_not_found('Patient not found') unless patient

    # Verificar se o usuário atual pode ver os resultados deste paciente
    return render_forbidden unless can_view_patient_results?(patient)

    # Buscar resultados com filtros opcionais
    results_query = ExamResult.joins(exam_request: :patient)
                              .where(exam_requests: { patient: patient })
                              .includes(exam_request: [:exam_type, :doctor], lab_technician: [])
                              .order(performed_at: :desc)

    # Filtrar por tipo de exame se especificado
    if params[:exam_type_id].present?
      results_query = results_query.joins(exam_request: :exam_type)
                                   .where(exam_requests: { exam_type_id: params[:exam_type_id] })
    end

    # Filtrar por data se especificado
    if params[:from_date].present?
      results_query = results_query.where('exam_results.performed_at >= ?', params[:from_date])
    end

    if params[:to_date].present?
      results_query = results_query.where('exam_results.performed_at <= ?', params[:to_date])
    end

    results = results_query.limit(params[:limit] || 50)

    # Agrupar por tipo de exame para trends
    results_by_type = results.group_by { |result| result.exam_request.exam_type }

    render json: {
      patient: user_response(patient),
      test_results: results.map { |result| detailed_exam_result_response(result) },
      trends: results_by_type.map do |exam_type, type_results|
        {
          exam_type: {
            id: exam_type.id,
            name: exam_type.name,
            unit: exam_type.unit,
            reference_range: exam_type.reference_range
          },
          results_count: type_results.count,
          latest_value: type_results.first&.value,
          latest_date: type_results.first&.performed_at,
          values_over_time: type_results.map do |result|
            {
              value: result.value,
              date: result.performed_at,
              status: determine_result_status(result.value, exam_type)
            }
          end
        }
      end
    }, status: :ok
  end

  private

  def find_patient
    User.joins(:roles)
        .where(roles: { name: 'patient' })
        .find_by(id: params[:patient_id])
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

  def detailed_patient_response(patient)
    doctors = patient.patient_doctors.distinct

    {
      id: patient.id,
      email: patient.email,
      name: patient.name,
      phone: patient.phone,
      created_at: patient.created_at,
      doctors: doctors.map { |doctor| user_response(doctor) },
      total_requests: patient.patient_exam_requests.count,
      completed_requests: patient.patient_exam_requests.joins(:exam_result).count,
      pending_requests: patient.patient_exam_requests.where(status: ['pending', 'scheduled']).count
    }
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      roles: user.roles.pluck(:name)
    }
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
        unit: request.exam_type.unit
      },
      scheduled_date: request.scheduled_date,
      status: request.status,
      notes: request.notes,
      result: request.exam_result ? exam_result_response(request.exam_result) : nil,
      created_at: request.created_at
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
      }
    }
  end

  def detailed_exam_result_response(result)
    {
      id: result.id,
      value: result.value,
      unit: result.unit,
      performed_at: result.performed_at,
      notes: result.notes,
      exam_request: {
        id: result.exam_request.id,
        scheduled_date: result.exam_request.scheduled_date,
        doctor: {
          id: result.exam_request.doctor.id,
          name: result.exam_request.doctor.name
        }
      },
      exam_type: {
        id: result.exam_request.exam_type.id,
        name: result.exam_request.exam_type.name,
        unit: result.exam_request.exam_type.unit,
        reference_range: result.exam_request.exam_type.reference_range
      },
      lab_technician: {
        id: result.lab_technician.id,
        name: result.lab_technician.name
      },
      status: determine_result_status(result.value, result.exam_request.exam_type)
    }
  end

  def determine_result_status(value, exam_type)
    # Lógica simples para determinar se o resultado está normal, alto ou baixo
    # Você pode expandir isso baseado nos reference_ranges
    'normal' # Por enquanto retorna sempre normal
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
