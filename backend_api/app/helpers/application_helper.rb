module ApplicationHelper
  def determine_result_status(value, exam_type)
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
end
