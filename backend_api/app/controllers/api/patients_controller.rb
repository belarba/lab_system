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

    # Filtros avançados
    requests = requests.where(status: params[:status]) if params[:status].present?
    requests = requests.joins(:exam_type).where(exam_types: { id: params[:exam_type_id] }) if params[:exam_type_id].present?
    requests = requests.joins(:doctor).where(users: { id: params[:doctor_id] }) if params[:doctor_id].present?
    requests = requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    requests = requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    # Paginação
    limit = [params[:limit].to_i, 50].min
    limit = 20 if limit <= 0
    offset = [params[:offset].to_i, 0].max

    requests = requests.limit(limit).offset(offset)

    render json: {
      patient: user_response(patient),
      blood_work_requests: requests.map { |request| exam_request_response(request) },
      pagination: {
        limit: limit,
        offset: offset,
        total: patient.patient_exam_requests.count
      }
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

    # Filtros avançados
    if params[:exam_type_id].present?
      results_query = results_query.joins(exam_request: :exam_type)
                                   .where(exam_requests: { exam_type_id: params[:exam_type_id] })
    end

    if params[:doctor_id].present?
      results_query = results_query.joins(exam_request: :doctor)
                                   .where(exam_requests: { doctor_id: params[:doctor_id] })
    end

    if params[:status].present?
      # Filtrar por status do resultado (normal, high, low)
      results_query = results_query.select do |result|
        determine_result_status(result.value, result.exam_request.exam_type) == params[:status]
      end
    end

    # Filtrar por data se especificado
    if params[:from_date].present?
      results_query = results_query.where('exam_results.performed_at >= ?', params[:from_date])
    end

    if params[:to_date].present?
      results_query = results_query.where('exam_results.performed_at <= ?', params[:to_date])
    end

    # Paginação
    limit = [params[:limit].to_i, 50].min
    limit = 20 if limit <= 0
    offset = [params[:offset].to_i, 0].max

    if results_query.is_a?(ActiveRecord::Relation)
      results = results_query.limit(limit).offset(offset)
      total_count = results_query.count
    else
      # Se filtrou por status, results_query é um array
      total_count = results_query.length
      results = results_query.drop(offset).take(limit)
    end

    # Agrupar por tipo de exame para trends
    all_results = results_query.is_a?(ActiveRecord::Relation) ? results_query.limit(200) : results_query.take(200)
    results_by_type = all_results.group_by { |result| result.exam_request.exam_type }

    render json: {
      patient: user_response(patient),
      test_results: results.map { |result| detailed_exam_result_response(result) },
      pagination: {
        limit: limit,
        offset: offset,
        total: total_count
      },
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
          average_value: type_results.map(&:value).sum / type_results.count.to_f,
          values_over_time: type_results.first(10).map do |result|
            {
              value: result.value,
              date: result.performed_at,
              status: determine_result_status(result.value, exam_type)
            }
          end
        }
      end,
      summary: {
        total_results: all_results.length,
        normal_count: all_results.count { |r| determine_result_status(r.value, r.exam_request.exam_type) == 'normal' },
        high_count: all_results.count { |r| determine_result_status(r.value, r.exam_request.exam_type) == 'high' },
        low_count: all_results.count { |r| determine_result_status(r.value, r.exam_request.exam_type) == 'low' },
        date_range: {
          earliest: all_results.map(&:performed_at).min,
          latest: all_results.map(&:performed_at).max
        }
      }
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
      statistics: {
        total_requests: patient.patient_exam_requests.count,
        completed_requests: patient.patient_exam_requests.joins(:exam_result).count,
        pending_requests: patient.patient_exam_requests.where(status: ['pending', 'scheduled']).count,
        cancelled_requests: patient.patient_exam_requests.where(status: 'cancelled').count,
        unique_exam_types: patient.patient_exam_requests.joins(:exam_type).distinct.count('exam_types.id'),
        last_result_date: patient.patient_exam_requests.joins(:exam_result).maximum('exam_results.performed_at')
      }
    }
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      phone: user.phone,
      roles: user.roles.pluck(:name)
    }
  end

  def exam_request_response(request)
    can_cancel = current_user.can_cancel_exam_request?(request) if current_user.patient?

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
      can_cancel: can_cancel,
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
      },
      status: determine_result_status(result.value, result.exam_request.exam_type)
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
    return 'normal' unless exam_type.reference_range.present?

    case exam_type.reference_range.downcase
    when /< (\d+\.?\d*)/
      max_value = $1.to_f
      value <= max_value ? 'normal' : 'high'
    when /(\d+\.?\d*)-(\d+\.?\d*)/
      min_value = $1.to_f
      max_value = $2.to_f
      if value < min_value
        'low'
      elsif value > max_value
        'high'
      else
        'normal'
      end
    else
      'normal'
    end
  end

  def render_not_found(message)
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
