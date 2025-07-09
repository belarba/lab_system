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

  # Helper para formatar datas
  def format_date(date)
    return nil unless date
    date.strftime('%Y-%m-%d')
  end

  # Helper para formatar data e hora
  def format_datetime(datetime)
    return nil unless datetime
    datetime.strftime('%Y-%m-%d %H:%M:%S')
  end

  # Helper para verificar se o usuário pode ver informações sensíveis
  def can_view_sensitive_info?(current_user, target_user)
    return true if current_user.admin?
    return true if current_user == target_user
    return true if current_user.doctor? && current_user.doctor_patients.include?(target_user)
    return true if current_user.lab_technician?
    false
  end
end
