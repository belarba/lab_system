class LabFileUpload < ApplicationRecord
  belongs_to :uploaded_by, class_name: 'User'
  has_many :exam_results, dependent: :nullify

  validates :filename, presence: true
  validates :status, inclusion: {
    in: %w[pending processing completed failed completed_with_warnings]
  }

  scope :by_status, ->(status) { where(status: status) }
  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: ['completed', 'completed_with_warnings']) }
  scope :failed, -> { where(status: 'failed') }

  def processing?
    status == 'processing'
  end

  def completed?
    status == 'completed'
  end

  def completed_with_warnings?
    status == 'completed_with_warnings'
  end

  def failed?
    status == 'failed'
  end

  def success_rate
    return 0 if total_records.zero?
    ((processed_records.to_f / total_records) * 100).round(2)
  end

  def failure_rate
    return 0 if total_records.zero?
    ((failed_records.to_f / total_records) * 100).round(2)
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

  def file_path
    summary = processing_summary_data
    summary['file_path']
  end

  def file_exists?
    path = file_path
    path.present? && File.exist?(path)
  end

  def file_size_human
    return 'Unknown' if file_size.blank?

    units = ['B', 'KB', 'MB', 'GB']
    size = file_size.to_f
    unit_index = 0

    while size >= 1024 && unit_index < units.length - 1
      size /= 1024
      unit_index += 1
    end

    "#{size.round(2)} #{units[unit_index]}"
  end

  def processing_duration
    return nil unless processed_at && created_at
    ((processed_at - created_at) / 1.minute).round(2)
  end

  def status_color
    case status
    when 'completed'
      'green'
    when 'completed_with_warnings'
      'yellow'
    when 'failed'
      'red'
    when 'processing'
      'blue'
    else
      'gray'
    end
  end

  def status_description
    case status
    when 'pending'
      'Aguardando processamento'
    when 'processing'
      'Processando arquivo...'
    when 'completed'
      'Processamento concluído com sucesso'
    when 'completed_with_warnings'
      'Processamento concluído com avisos'
    when 'failed'
      'Falha no processamento'
    else
      status.humanize
    end
  end

  def can_reprocess?
    ['failed', 'completed_with_warnings'].include?(status) && file_exists?
  end

  def processing_errors
    return [] unless failed? || completed_with_warnings?

    summary = processing_summary_data
    details = summary['details'] || []

    details.select { |detail| detail['message'].to_s.include?('failed') }
  end

  def sample_errors(limit = 5)
    processing_errors.first(limit)
  end
end
