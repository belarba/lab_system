class User < ApplicationRecord
  has_secure_password

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :phone, format: { with: /\A[\+]?[0-9\s\-\(\)]{7,15}\z/, message: "must be a valid phone number" }, allow_blank: true

  # Como paciente
  has_many :patient_exam_requests, class_name: "ExamRequest", foreign_key: "patient_id"
  has_many :patient_doctors, -> { distinct }, through: :patient_exam_requests, source: :doctor

  # Como médico
  has_many :doctor_exam_requests, class_name: "ExamRequest", foreign_key: "doctor_id"
  has_many :doctor_patients, -> { distinct }, through: :doctor_exam_requests, source: :patient

  # Como técnico de laboratório
  has_many :lab_exam_results, class_name: "ExamResult", foreign_key: "lab_technician_id"

  has_many :refresh_tokens, dependent: :destroy

  def generate_tokens
    access_token = JwtService.encode_access_token(id)
    refresh_token_jwt = JwtService.encode_refresh_token(id)

    # Salvar refresh token no banco
    refresh_token_record = refresh_tokens.create!(
      token: refresh_token_jwt,
      expires_at: REFRESH_TOKEN_EXPIRATION.from_now
    )

    {
      access_token: access_token,
      refresh_token: refresh_token_jwt,
      expires_in: ACCESS_TOKEN_EXPIRATION.to_i
    }
  end

  def revoke_all_tokens
    refresh_tokens.destroy_all
  end

  # Métodos helper para verificar roles
  def has_role?(role_name)
    roles.exists?(name: role_name)
  end

  def patient?
    has_role?("patient")
  end

  def doctor?
    has_role?("doctor")
  end

  def lab_technician?
    has_role?("lab_technician")
  end

  def admin?
    has_role?("admin")
  end

  # Método para verificar se pode solicitar exame (1 por semana do mesmo tipo)
  def can_request_exam?(exam_type)
    return false unless patient?

    one_week_ago = 1.week.ago
    existing_request = patient_exam_requests
                      .where(exam_type: exam_type)
                      .where(created_at: one_week_ago..Time.current)
                      .where.not(status: 'cancelled')
                      .exists?

    !existing_request
  end

  # Método para verificar se pode cancelar exame (até 3 horas antes)
  def can_cancel_exam_request?(exam_request)
    return false unless exam_request.patient == self || exam_request.doctor == self || admin?
    return false if exam_request.completed? || exam_request.status == 'cancelled'

    # Pacientes só podem cancelar até 3 horas antes
    if patient? && exam_request.patient == self
      return exam_request.scheduled_date > 3.hours.from_now
    end

    # Médicos e admins podem cancelar a qualquer momento
    true
  end
end
