class ExamResult < ApplicationRecord
  belongs_to :exam_request
  belongs_to :lab_technician, class_name: 'User'

  validates :value, presence: true, numericality: true
  validates :unit, presence: true
  validates :performed_at, presence: true

  # Callback para marcar a requisição como completa
  after_create :mark_request_as_completed

  private

  def mark_request_as_completed
    exam_request.update(status: "completed")
  end
end
