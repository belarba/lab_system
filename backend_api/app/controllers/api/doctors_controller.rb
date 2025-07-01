class Api::DoctorsController < ApplicationController
  include Authenticable

  def patients
    doctor = find_doctor
    return render_not_found('Doctor not found') unless doctor

    # Verificar se o usuário atual pode ver os pacientes deste médico
    return render_forbidden unless can_view_doctor_patients?(doctor)

    patients = doctor.doctor_patients
                    .joins(:roles)
                    .where(roles: { name: 'patient' })
                    .distinct
                    .includes(:roles)

    # Filtros opcionais
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      patients = patients.where("users.name ILIKE ? OR users.email ILIKE ?", search_term, search_term)
    end

    render json: {
      doctor: user_response(doctor),
      patients: patients.map { |patient| patient_response(patient, doctor) }
    }, status: :ok
  end

  def blood_work_requests
    doctor = find_doctor
    return render_not_found('Doctor not found') unless doctor

    # Verificar se o usuário atual pode ver as requisições deste médico
    return render_forbidden unless can_view_doctor_requests?(doctor)

    requests = doctor.doctor_exam_requests
                    .includes(:patient, :exam_type, :exam_result)
                    .order(scheduled_date: :desc)

    # Filtros
    requests = requests.where(status: params[:status]) if params[:status].present?
    requests = requests.joins(:exam_type).where(exam_types: { id: params[:exam_type_id] }) if params[:exam_type_id].present?
    requests = requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    requests = requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    render json: {
      doctor: user_response(doctor),
      blood_work_requests: requests.map { |request| exam_request_response(request) }
    }, status: :ok
  end

  def export_patient_results
    doctor = find_doctor
    return render_not_found('Doctor not found') unless doctor
    return render_forbidden unless can_view_doctor_requests?(doctor)

    patient = doctor.doctor_patients.find_by(id: params[:patient_id])
    return render_not_found('Patient not found or not associated with this doctor') unless patient

    # Buscar resultados
    results_query = ExamResult.joins(exam_request: [:patient, :doctor, :exam_type])
                              .where(exam_requests: { patient: patient, doctor: doctor })
                              .includes(exam_request: [:exam_type], lab_technician: [])
                              .order(performed_at: :desc)

    # Filtros
    results_query = results_query.joins(exam_request: :exam_type).where(exam_requests: { exam_type_id: params[:exam_type_id] }) if params[:exam_type_id].present?
    results_query = results_query.where('exam_results.performed_at >= ?', params[:from_date]) if params[:from_date].present?
    results_query = results_query.where('exam_results.performed_at <= ?', params[:to_date]) if params[:to_date].present?

    results = results_query.all

    # Gerar CSV
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'Patient Name',
        'Patient Email',
        'Test Type',
        'Value',
        'Unit',
        'Reference Range',
        'Performed At',
        'Lab Technician',
        'Status',
        'Notes'
      ]

      results.each do |result|
        status = determine_result_status(result.value, result.exam_request.exam_type)
        csv << [
          result.exam_request.patient.name,
          result.exam_request.patient.email,
          result.exam_request.exam_type.name,
          result.value,
          result.unit,
          result.exam_request.exam_type.reference_range,
          result.performed_at.iso8601,
          result.lab_technician.name,
          status,
          result.notes
        ]
      end
    end

    # Responder com CSV
    respond_to do |format|
      format.csv do
        filename = "patient_results_#{patient.name.parameterize}_#{Date.current}.csv"
        send_data csv_data,
                  filename: filename,
                  type: 'text/csv',
                  disposition: 'attachment'
      end
      format.json do
        render json: {
          message: 'CSV data generated successfully',
          csv_data: csv_data,
          results_count: results.count,
          patient: {
            id: patient.id,
            name: patient.name,
            email: patient.email
          }
        }
      end
    end
  end

  def export_all_results
    doctor = find_doctor
    return render_not_found('Doctor not found') unless doctor
    return render_forbidden unless can_view_doctor_requests?(doctor)

    # Buscar todos os resultados do médico
    results_query = ExamResult.joins(exam_request: [:patient, :doctor, :exam_type])
                              .where(exam_requests: { doctor: doctor })
                              .includes(exam_request: [:patient, :exam_type], lab_technician: [])
                              .order(performed_at: :desc)

    # Filtros
    results_query = results_query.joins(exam_request: :exam_type).where(exam_requests: { exam_type_id: params[:exam_type_id] }) if params[:exam_type_id].present?
    results_query = results_query.where('exam_results.performed_at >= ?', params[:from_date]) if params[:from_date].present?
    results_query = results_query.where('exam_results.performed_at <= ?', params[:to_date]) if params[:to_date].present?

    results = results_query.all

    # Gerar CSV
    require 'csv'
    csv_data = CSV.generate(headers: true) do |csv|
      csv << [
        'Patient Name',
        'Patient Email',
        'Patient Phone',
        'Test Type',
        'Value',
        'Unit',
        'Reference Range',
        'Performed At',
        'Scheduled Date',
        'Lab Technician',
        'Status',
        'Result Notes',
        'Request Notes'
      ]

      results.each do |result|
        status = determine_result_status(result.value, result.exam_request.exam_type)
        csv << [
          result.exam_request.patient.name,
          result.exam_request.patient.email,
          result.exam_request.patient.phone,
          result.exam_request.exam_type.name,
          result.value,
          result.unit,
          result.exam_request.exam_type.reference_range,
          result.performed_at.iso8601,
          result.exam_request.scheduled_date.iso8601,
          result.lab_technician.name,
          status,
          result.notes,
          result.exam_request.notes
        ]
      end
    end

    respond_to do |format|
      format.csv do
        filename = "all_patient_results_#{doctor.name.parameterize}_#{Date.current}.csv"
        send_data csv_data,
                  filename: filename,
                  type: 'text/csv',
                  disposition: 'attachment'
      end
      format.json do
        render json: {
          message: 'CSV data generated successfully',
          csv_data: csv_data,
          results_count: results.count,
          doctor: user_response(doctor)
        }
      end
    end
  end

  def add_patient
    doctor = find_doctor
    return render_forbidden unless can_manage_patients?(doctor)

    patient_email = params[:patient_email]&.strip&.downcase
    return render json: { error: 'Email do paciente é obrigatório' }, status: :bad_request unless patient_email.present?

    # Buscar paciente pelo email
    patient = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .find_by('LOWER(email) = ?', patient_email)

    unless patient
      return render json: { error: 'Paciente não encontrado com este email' }, status: :not_found
    end

    # Verificar se já não é paciente deste médico
    if doctor.doctor_patients.include?(patient)
      return render json: { error: 'Este paciente já está associado a você' }, status: :unprocessable_entity
    end

    # Criar uma requisição "virtual" para estabelecer a relação
    # Vamos usar um tipo de exame padrão ou criar um tipo especial
    default_exam_type = ExamType.find_or_create_by(name: 'Cadastro Inicial') do |et|
      et.description = 'Tipo de exame usado para estabelecer relação médico-paciente'
      et.unit = 'N/A'
      et.reference_range = 'N/A'
    end

    begin
      # Criar requisição inicial (pode ser cancelada imediatamente)
      exam_request = ExamRequest.create!(
        patient: patient,
        doctor: doctor,
        exam_type: default_exam_type,
        scheduled_date: 1.day.from_now,
        status: 'cancelled', # Já criar como cancelada
        notes: 'Requisição automática para estabelecer relação médico-paciente'
      )

      render json: {
        message: 'Paciente adicionado com sucesso',
        patient: patient_response(patient, doctor)
      }, status: :created

    rescue => e
      Rails.logger.error "Erro ao adicionar paciente: #{e.message}"
      render json: { error: 'Erro interno ao adicionar paciente' }, status: :internal_server_error
    end
  end

  def search_patients
    doctor = find_doctor
    return render_forbidden unless can_manage_patients?(doctor)

    search_term = params[:search]&.strip
    return render json: { error: 'Termo de busca é obrigatório' }, status: :bad_request unless search_term.present?

    # Buscar pacientes que não são deste médico
    existing_patient_ids = doctor.doctor_patients.pluck(:id)

    patients = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .where.not(id: existing_patient_ids)
                  .where('LOWER(name) LIKE ? OR LOWER(email) LIKE ?',
                          "%#{search_term.downcase}%",
                          "%#{search_term.downcase}%")
                  .limit(10)

    render json: {
      patients: patients.map { |patient|
        {
          id: patient.id,
          name: patient.name,
          email: patient.email,
          phone: patient.phone
        }
      }
    }, status: :ok
  end

  def remove_patient
    doctor = find_doctor
    return render_forbidden unless can_manage_patients?(doctor)

    patient = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .find_by(id: params[:patient_id])

    unless patient
      return render json: { error: 'Paciente não encontrado' }, status: :not_found
    end

    unless doctor.doctor_patients.include?(patient)
      return render json: { error: 'Este paciente não está associado a você' }, status: :unprocessable_entity
    end

    # Verificar se tem exames não cancelados
    active_requests = doctor.doctor_exam_requests
                            .where(patient: patient)
                            .where.not(status: 'cancelled')

    if active_requests.any?
      return render json: {
        error: 'Não é possível remover paciente com exames ativos. Cancele os exames primeiro.',
        active_requests_count: active_requests.count
      }, status: :unprocessable_entity
    end

    # Cancelar todas as requisições restantes (se houver)
    doctor.doctor_exam_requests
          .where(patient: patient)
          .update_all(status: 'cancelled', updated_at: Time.current)

    render json: {
      message: 'Paciente removido com sucesso'
    }, status: :ok
  end

  private

  def can_manage_patients?(doctor)
    current_user.admin? || current_user == doctor
  end

  def patient_response(patient, doctor)
    recent_requests = patient.patient_exam_requests
                            .where(doctor: doctor)
                            .order(scheduled_date: :desc)
                            .limit(5)

    {
      id: patient.id,
      email: patient.email,
      name: patient.name,
      phone: patient.phone,
      recent_requests_count: recent_requests.count,
      last_request_date: recent_requests.first&.scheduled_date,
      total_results: patient.patient_exam_requests.joins(:exam_result).where(doctor: doctor).count,
      added_at: recent_requests.last&.created_at || Time.current
    }
  end

  def find_doctor
    User.joins(:roles)
        .where(roles: { name: 'doctor' })
        .find_by(id: params[:doctor_id])
  end

  def can_view_doctor_patients?(doctor)
    # Admin pode ver tudo, médico pode ver seus próprios pacientes
    current_user.admin? || current_user == doctor
  end

  def can_view_doctor_requests?(doctor)
    # Admin pode ver tudo, médico pode ver suas próprias requisições
    current_user.admin? || current_user == doctor
  end

  def patient_response(patient, doctor)
    # Últimas requisições do paciente com este médico
    recent_requests = patient.patient_exam_requests
                            .where(doctor: doctor)
                            .order(scheduled_date: :desc)
                            .limit(5)

    {
      id: patient.id,
      email: patient.email,
      name: patient.name,
      phone: patient.phone,
      recent_requests_count: recent_requests.count,
      last_request_date: recent_requests.first&.scheduled_date,
      total_results: patient.patient_exam_requests.joins(:exam_result).where(doctor: doctor).count
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
    {
      id: request.id,
      patient: {
        id: request.patient.id,
        name: request.patient.name,
        email: request.patient.email,
        phone: request.patient.phone
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
      },
      status: determine_result_status(result.value, result.exam_request.exam_type),
      notes: result.notes
    }
  end

  def determine_result_status(value, exam_type)
    # Implementação simples - você pode expandir com lógica mais complexa
    return 'normal' unless exam_type.reference_range.present?

    # Tentar extrair range numérico básico do reference_range
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
