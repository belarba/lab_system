class ExamRequest < ApplicationRecord
  belongs_to :patient, class_name: "User"
  belongs_to :doctor, class_name: "User"
  belongs_to :exam_type
  has_one :exam_result, dependent: :destroy

  validates :scheduled_date, presence: true
  validates :status, inclusion: { in: %w[pending scheduled completed cancelled] }

  scope :pending, -> { where(status: "pending") }
  scope :completed, -> { where(status: "completed") }
  scope :for_patient, ->(patient_id) { where(patient_id: patient_id) }
  scope :for_doctor, ->(doctor_id) { where(doctor_id: doctor_id) }

  def completed?
    status == "completed" && exam_result.present?
  end
end
