class Api::DoctorsController < ApplicationController
  include Authenticable
  before_action :set_doctor, only: [:patients, :blood_work_requests, :export_patient_results, :export_all_results, :add_patient]

  def patients
    return render_forbidden unless can_view_doctor_patients?(@doctor)

    @patients = @doctor.doctor_patients
                      .joins(:roles)
                      .where(roles: { name: 'patient' })
                      .distinct
                      .includes(:roles)

    # Filtros opcionais
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @patients = @patients.where("users.name ILIKE ? OR users.email ILIKE ?", search_term, search_term)
    end

    render 'api/doctors/patients'
  end

  def search_patients
    return render_forbidden unless current_user.doctor? || current_user.admin?

    search_term = params[:search]
    return render json: { patients: [] } if search_term.blank?

    @patients = User.joins(:roles)
                   .where(roles: { name: 'patient' })
                   .where("users.name ILIKE ? OR users.email ILIKE ?", "%#{search_term}%", "%#{search_term}%")
                   .includes(:roles)
                   .limit(20)

    render 'api/doctors/search_patients'
  end

  def add_patient
    return render_forbidden unless current_user.doctor? || current_user.admin?

    patient_id = params[:patient_id]
    return render json: { error: 'Patient ID is required' }, status: :bad_request if patient_id.blank?

    @patient = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .find_by(id: patient_id)

    return render_not_found('Patient not found') unless @patient

    # Verificar se já existe uma relação
    existing_relation = ExamRequest.exists?(doctor: @doctor, patient: @patient)

    if existing_relation
      render 'api/doctors/add_patient_existing'
    else
      render 'api/doctors/add_patient_new'
    end
  end

  def all_patients
    return render_forbidden unless current_user.doctor? || current_user.admin?

    @patients = User.joins(:roles)
                   .where(roles: { name: 'patient' })
                   .includes(:roles)
                   .order(:name)

    # Filtros opcionais
    if params[:search].present?
      search_term = "%#{params[:search]}%"
      @patients = @patients.where("users.name ILIKE ? OR users.email ILIKE ?", search_term, search_term)
    end

    # Paginação
    @limit = [params[:limit].to_i, 50].min
    @limit = 20 if @limit <= 0
    @offset = [params[:offset].to_i, 0].max
    @total = User.joins(:roles).where(roles: { name: 'patient' }).count

    @patients = @patients.limit(@limit).offset(@offset)

    render 'api/doctors/all_patients'
  end

  def blood_work_requests
    return render_forbidden unless can_view_doctor_requests?(@doctor)

    @requests = @doctor.doctor_exam_requests
                      .includes(:patient, :exam_type, :exam_result)
                      .order(scheduled_date: :desc)

    # Filtros
    @requests = @requests.where(status: params[:status]) if params[:status].present?
    @requests = @requests.joins(:exam_type).where(exam_types: { id: params[:exam_type_id] }) if params[:exam_type_id].present?
    @requests = @requests.where('scheduled_date >= ?', params[:from_date]) if params[:from_date].present?
    @requests = @requests.where('scheduled_date <= ?', params[:to_date]) if params[:to_date].present?

    render 'api/doctors/blood_work_requests'
  end

  def export_patient_results
    return render_forbidden unless can_view_doctor_requests?(@doctor)

    @patient = @doctor.doctor_patients.find_by(id: params[:patient_id])
    return render_not_found('Patient not found or not associated with this doctor') unless @patient

    # Buscar resultados com filtros
    @results = build_results_query(@patient, @doctor)
    @csv_data = generate_patient_csv(@results, @patient)

    render 'api/doctors/export_patient_results'
  end

  def export_all_results
    return render_forbidden unless can_view_doctor_requests?(@doctor)

    # Buscar todos os resultados do médico com filtros
    @results = build_results_query(nil, @doctor)
    @csv_data = generate_all_results_csv(@results)

    render 'api/doctors/export_all_results'
  end

  private

  def set_doctor
    @doctor = User.joins(:roles)
                  .where(roles: { name: 'doctor' })
                  .find_by(id: params[:id] || params[:doctor_id])

    return render_not_found('Doctor not found') unless @doctor
  end

  def can_view_doctor_patients?(doctor = @doctor)
    current_user.admin? || current_user == doctor
  end

  def can_view_doctor_requests?(doctor = @doctor)
    current_user.admin? || current_user == doctor
  end

  def build_results_query(patient = nil, doctor)
    query = ExamResult.joins(exam_request: [:patient, :doctor, :exam_type])
                      .where(exam_requests: { doctor: doctor })
                      .includes(exam_request: [:patient, :exam_type], lab_technician: [])
                      .order(performed_at: :desc)

    query = query.where(exam_requests: { patient: patient }) if patient

    # Aplicar filtros
    query = query.joins(exam_request: :exam_type).where(exam_requests: { exam_type_id: params[:exam_type_id] }) if params[:exam_type_id].present?
    query = query.where('exam_results.performed_at >= ?', params[:from_date]) if params[:from_date].present?
    query = query.where('exam_results.performed_at <= ?', params[:to_date]) if params[:to_date].present?

    query.all
  end

  def generate_patient_csv(results, patient)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << [
        'Patient Name', 'Patient Email', 'Test Type', 'Value', 'Unit',
        'Reference Range', 'Performed At', 'Lab Technician', 'Status', 'Notes'
      ]

      results.each do |result|
        status = helpers.determine_result_status(result.value, result.exam_request.exam_type)
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
  end

  def generate_all_results_csv(results)
    require 'csv'
    CSV.generate(headers: true) do |csv|
      csv << [
        'Patient Name', 'Patient Email', 'Patient Phone', 'Test Type', 'Value', 'Unit',
        'Reference Range', 'Performed At', 'Scheduled Date', 'Lab Technician',
        'Status', 'Result Notes', 'Request Notes'
      ]

      results.each do |result|
        status = helpers.determine_result_status(result.value, result.exam_request.exam_type)
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
  end

  def render_not_found(message = 'Resource not found')
    render json: { error: message }, status: :not_found
  end

  def render_forbidden
    render json: { error: 'Forbidden' }, status: :forbidden
  end
end
