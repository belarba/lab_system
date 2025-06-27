class LabFileUpload < ApplicationRecord
  belongs_to :uploaded_by, class_name: 'User'

  validates :filename, presence: true
  validates :status, inclusion: { in: %w[pending processing completed failed] }

  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }

  def processing?
    status == 'processing'
  end

  def completed?
    status == 'completed'
  end

  def failed?
    status == 'failed'
  end

  def success_rate
    return 0 if total_records.zero?
    ((processed_records.to_f / total_records) * 100).round(2)
  end

  def processing_summary_data
    return {} if processing_summary.blank?
    JSON.parse(processing_summary)
  rescue JSON::ParserError
    {}
  end

  def add_processing_detail(detail)
    summary = processing_summary_data
    summary['details'] ||= []
    summary['details'] << {
      timestamp: Time.current.iso8601,
      message: detail
    }
    update!(processing_summary: summary.to_json)
  end
end
