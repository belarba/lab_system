class User < ApplicationRecord
  has_secure_password

  has_many :user_roles, dependent: :destroy
  has_many :roles, through: :user_roles

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true

  # Como paciente
  has_many :patient_exam_requests, class_name: "ExamRequest", foreign_key: "patient_id"
  has_many :patient_doctors, -> { distinct }, through: :patient_exam_requests, source: :doctor

  # Como médico
  has_many :doctor_exam_requests, class_name: "ExamRequest", foreign_key: "doctor_id"
  has_many :doctor_patients, -> { distinct }, through: :doctor_exam_requests, source: :patient

  # Como técnico de laboratório
  has_many :lab_exam_results, class_name: "ExamResult", foreign_key: "lab_technician_id"

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
end
