class ExamType < ApplicationRecord
  has_many :exam_requests, dependent: :destroy
  has_many :exam_results, through: :exam_requests

  validates :name, presence: true, uniqueness: true
  validates :unit, presence: true
end
