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

    render json: {
      doctor: user_response(doctor),
      blood_work_requests: requests.map { |request| exam_request_response(request) }
    }, status: :ok
  end

  private

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
      last_request_date: recent_requests.first&.scheduled_date
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
      patient: {
        id: request.patient.id,
        name: request.patient.name,
        email: request.patient.email
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
