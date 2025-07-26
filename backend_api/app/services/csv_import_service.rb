class CsvImportService
  require 'csv'

  attr_reader :upload, :file_content, :processed_count, :failed_count, :processing_details

  def initialize(lab_file_upload, file_content)
    @upload = lab_file_upload
    @file_content = file_content
    @processed_count = 0
    @failed_count = 0
    @processing_details = []
    @file_path = nil
  end

  def process
    ActiveRecord::Base.transaction do
      @upload.update!(
        status: 'processing',
        processing_started_at: Time.current,
        processed_at: Time.current
      )
      add_detail("Started processing CSV file: #{@upload.filename}")

      begin
        # Analisar arquivo antes do processamento
        analyzer = CsvAnalyzerService.new(@file_content)
        analyzer.analyze

        unless analyzer.valid_for_import?
          raise "File validation failed: #{analyzer.validation_errors.join(', ')}"
        end

        # Salvar informações da análise
        update_file_analysis(analyzer.analysis_result)
        add_detail("File analysis completed successfully")

        # Salvar arquivo no servidor
        @file_path = save_file_to_server
        add_detail("File saved to server: #{@file_path}")

        # Parse CSV com delimitador detectado
        rows = parse_csv(@file_content, analyzer.analysis_result[:delimiter])
        @upload.update!(total_records: rows.count)
        add_detail("Found #{rows.count} records to process")

        # Processar em lotes para melhor performance
        process_rows_in_batches(rows)

        # Finalizar status
        update_final_status

      rescue => e
        handle_critical_error(e)
        raise ActiveRecord::Rollback # Rollback da transação principal
      end
    end
  end

  private

  def save_file_to_server
    # Criar diretório para uploads se não existir
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    FileUtils.mkdir_p(upload_dir)

    # Gerar nome único para o arquivo
    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    filename = "#{timestamp}_#{@upload.id}_#{sanitize_filename(@upload.filename)}"
    file_path = upload_dir.join(filename)

    # Salvar conteúdo no arquivo
    File.write(file_path, @file_content)

    # Atualizar upload com caminho do arquivo
    @upload.update!(processing_summary: { file_path: file_path.to_s }.to_json)

    file_path.to_s
  end

  def sanitize_filename(filename)
    # Remove caracteres perigosos do nome do arquivo
    filename.gsub(/[^\w\-.]/, '_')
  end

  def parse_csv(content, delimiter = ',')
    begin
      CSV.parse(content, headers: true, header_converters: :symbol, col_sep: delimiter)
    rescue CSV::MalformedCSVError => e
      raise "Invalid CSV format: #{e.message}"
    end
  end

  def update_file_analysis(analysis)
    @upload.update!(
      file_hash: analysis[:file_hash],
      file_encoding: analysis[:encoding],
      detected_delimiter: analysis[:delimiter],
      detected_headers: analysis[:headers].to_json
    )
  end

  def process_rows_in_batches(rows)
    batch_size = 50 # Processar em lotes de 50 registros

    rows.each_slice(batch_size).with_index do |batch, batch_index|
      add_detail("Processing batch #{batch_index + 1} (#{batch.size} records)")

      process_batch(batch, batch_index * batch_size)

      # Atualizar progresso a cada lote
      @upload.update!(
        processed_records: @processed_count,
        failed_records: @failed_count
      )
    end
  end

  def process_batch(batch, start_index)
    batch.each_with_index do |row, index|
      row_number = start_index + index + 1

      begin
        # Usar sub-transação para cada linha
        ActiveRecord::Base.transaction(requires_new: true) do
          process_single_row(row, row_number)
          @processed_count += 1
        end

      rescue => e
        @failed_count += 1
        error_message = "Row #{row_number} failed: #{e.message}"
        add_detail(error_message)
        Rails.logger.warn "CSV Import - #{error_message}"

        # Continuar processamento mesmo com erro
        next
      end
    end
  end

  def process_single_row(row, row_number)
    # Validar dados da linha
    validate_row_data(row, row_number)

    # Encontrar entidades necessárias
    patient = find_patient(row[:patient_email])
    exam_type = find_exam_type(row[:test_type])
    lab_technician = find_lab_technician
    measured_at = parse_datetime(row[:measured_at])

    # Procurar ou criar requisição de exame
    exam_request = find_or_create_exam_request(patient, exam_type, measured_at)

    # Verificar se já existe resultado para esta requisição
    if exam_request.exam_result.present?
      add_detail("Row #{row_number}: Exam request #{exam_request.id} already has a result, skipping")
      # Considerar como processado mesmo que tenha sido pulado
      return
    end

    # Criar o resultado do exame
    exam_result = ExamResult.create!(
      exam_request: exam_request,
      value: parse_numeric_value(row[:measured_value]),
      unit: row[:unit].to_s.strip,
      lab_technician: lab_technician,
      performed_at: measured_at,
      lab_file_upload: @upload,
      notes: build_result_notes(row_number, row)
    )

    add_detail("Row #{row_number}: Created exam result ##{exam_result.id} for #{patient.email}")
  end

  def validate_row_data(row, row_number)
    required_fields = [:patient_email, :test_type, :measured_value, :unit, :measured_at]
    missing_fields = []

    required_fields.each do |field|
      if row[field].blank?
        missing_fields << field
      end
    end

    if missing_fields.any?
      raise "Missing required fields: #{missing_fields.join(', ')}"
    end

    # Validar valor numérico
    value = row[:measured_value].to_s.strip
    unless value.match?(/^\d+(?:\.\d+)?$/)
      raise "Invalid measured_value '#{value}' - must be a valid number"
    end

    # Validar email format
    email = row[:patient_email].to_s.strip
    unless email.match?(/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i)
      raise "Invalid email format: #{email}"
    end
  end

  def parse_numeric_value(value)
    parsed = value.to_s.strip.to_f
    if parsed <= 0
      raise "Value must be greater than 0"
    end
    parsed
  end

  def find_patient(email)
    email = email.to_s.strip.downcase
    patient = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .where('LOWER(email) = ?', email)
                  .first

    unless patient
      raise "Patient not found with email: #{email}"
    end

    patient
  end

  def find_exam_type(test_type)
    test_type = test_type.to_s.strip
    exam_type = ExamType.where('LOWER(name) = ?', test_type.downcase).first

    unless exam_type
      # Sugerir tipos similares
      similar_types = ExamType.where('name ILIKE ?', "%#{test_type}%").limit(3).pluck(:name)
      suggestion = similar_types.any? ? " Similar types: #{similar_types.join(', ')}" : ""
      raise "Exam type not found: #{test_type}.#{suggestion}"
    end

    exam_type
  end

  def find_or_create_exam_request(patient, exam_type, measured_at)
    # Procurar requisição existente próxima à data (±3 dias)
    date_range = (measured_at - 3.days)..(measured_at + 3.days)

    existing_request = ExamRequest.joins(:patient, :exam_type)
                                  .where(
                                    patient: patient,
                                    exam_type: exam_type,
                                    scheduled_date: date_range
                                  )
                                  .where.not(status: 'cancelled')
                                  .first

    if existing_request
      existing_request
    else
      # Criar nova requisição automaticamente
      doctor = find_available_doctor

      ExamRequest.create!(
        patient: patient,
        doctor: doctor,
        exam_type: exam_type,
        scheduled_date: measured_at,
        status: 'completed',
        notes: "Auto-created from CSV import ##{@upload.id} on #{Time.current.strftime('%Y-%m-%d %H:%M')}"
      )
    end
  end

  def find_available_doctor
    # Procurar médico menos carregado ou o primeiro disponível
    doctor = User.joins(:roles)
                 .where(roles: { name: 'doctor' })
                 .left_joins(:doctor_exam_requests)
                 .group('users.id')
                 .order('COUNT(exam_requests.id) ASC')
                 .first

    unless doctor
      raise "No doctor available to create exam request"
    end

    doctor
  end

  def find_lab_technician
    # Priorizar o usuário que fez upload se for lab technician
    if @upload.uploaded_by.lab_technician?
      @upload.uploaded_by
    else
      # Senão, pegar qualquer lab tech disponível
      lab_technician = User.joins(:roles).where(roles: { name: 'lab_technician' }).first
      unless lab_technician
        raise "No lab technician available"
      end
      lab_technician
    end
  end

  def parse_datetime(datetime_str)
    datetime_str = datetime_str.to_s.strip

    # Tentar diferentes formatos de data
    formats = [
      '%Y-%m-%dT%H:%M:%S%z',      # ISO 8601 with timezone
      '%Y-%m-%dT%H:%M:%SZ',       # ISO 8601 UTC
      '%Y-%m-%d %H:%M:%S',        # Standard format
      '%Y-%m-%d',                 # Date only
      '%d/%m/%Y %H:%M:%S',        # Brazilian format
      '%d/%m/%Y'                  # Brazilian date only
    ]

    formats.each do |format|
      begin
        return DateTime.strptime(datetime_str, format)
      rescue ArgumentError
        next
      end
    end

    # Se nenhum formato funcionou, tentar parse automático
    begin
      DateTime.parse(datetime_str)
    rescue ArgumentError
      raise "Invalid datetime format: #{datetime_str}. Supported formats: YYYY-MM-DD HH:MM:SS, DD/MM/YYYY HH:MM:SS"
    end
  end

  def build_result_notes(row_number, row)
    notes = ["Imported from CSV upload ##{@upload.id} (row #{row_number})"]

    # Adicionar informações extras se disponíveis
    if row[:notes].present?
      notes << "Original notes: #{row[:notes]}"
    end

    if row[:reference_value].present?
      notes << "Reference value: #{row[:reference_value]}"
    end

    notes.join('. ')
  end

  def add_detail(message)
    timestamp = Time.current.iso8601
    detail = {
      timestamp: timestamp,
      message: message
    }

    @processing_details << detail

    # Log importante para debugging
    Rails.logger.info "CSV Import [#{@upload.id}]: #{message}"
  end

  def update_final_status
    total_processed = @processed_count + @failed_count
    success_rate = @upload.total_records > 0 ? ((@processed_count.to_f / @upload.total_records) * 100).round(2) : 0

    summary = {
      total_records: @upload.total_records,
      processed_records: @processed_count,
      failed_records: @failed_count,
      success_rate: success_rate,
      file_path: @file_path,
      processing_started_at: @upload.processing_started_at&.iso8601,
      processing_completed_at: Time.current.iso8601,
      details: @processing_details
    }

    # Determinar status final
    final_status = determine_final_status

    @upload.update!(
      status: final_status,
      processed_records: @processed_count,
      failed_records: @failed_count,
      processing_completed_at: Time.current,
      processing_summary: summary.to_json
    )

    add_detail("Processing completed. Status: #{final_status}, Success rate: #{success_rate}%")
  end

  def determine_final_status
    if @failed_count == 0 && @processed_count > 0
      'completed'
    elsif @processed_count == 0 && @failed_count > 0
      'failed'
    elsif @processed_count > 0 && @failed_count > 0
      'completed_with_warnings'
    else
      'failed'
    end
  end

  def handle_critical_error(error)
    error_message = "Critical error during CSV processing: #{error.message}"

    @upload.update!(
      status: 'failed',
      error_details: error_message,
      processing_summary: {
        error: error_message,
        processed_records: @processed_count,
        failed_records: @failed_count,
        details: @processing_details,
        backtrace: error.backtrace&.first(10)
      }.to_json
    )

    add_detail(error_message)
    Rails.logger.error "CSV Import Critical Error [#{@upload.id}]: #{error.message}"
    Rails.logger.error error.backtrace.join("\n") if error.backtrace
  end
end
