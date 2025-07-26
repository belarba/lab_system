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
    # Inicializar processamento
    start_processing

    begin
      # Analisar arquivo
      analyzer = analyze_file
      return if analyzer.nil?

      # Salvar arquivo no servidor
      save_file_to_server

      # Processar dados
      process_csv_data(analyzer)

      # Finalizar com sucesso
      finalize_processing

    rescue => e
      handle_critical_error(e)
    end
  end

  private

  def start_processing
    @upload.update!(
      status: 'processing',
      processing_started_at: Time.current,
      processed_at: Time.current
    )
    add_detail("Started processing CSV file: #{@upload.filename}")
  end

  def analyze_file
    analyzer = CsvAnalyzerService.new(@file_content)
    analyzer.analyze

    unless analyzer.valid_for_import?
      error_message = "File validation failed: #{analyzer.validation_errors.join(', ')}"
      fail_upload(error_message)
      return nil
    end

    # Salvar informações da análise
    @upload.update!(
      file_hash: analyzer.analysis_result[:file_hash],
      file_encoding: analyzer.analysis_result[:encoding],
      detected_delimiter: analyzer.analysis_result[:delimiter],
      detected_headers: analyzer.analysis_result[:headers].to_json
    )

    add_detail("File analysis completed successfully")
    analyzer
  end

  def save_file_to_server
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    FileUtils.mkdir_p(upload_dir)

    timestamp = Time.current.strftime('%Y%m%d_%H%M%S')
    filename = "#{timestamp}_#{@upload.id}_#{sanitize_filename(@upload.filename)}"
    @file_path = upload_dir.join(filename)

    File.write(@file_path, @file_content)
    add_detail("File saved to server: #{@file_path}")
  end

  def process_csv_data(analyzer)
    rows = parse_csv(@file_content, analyzer.analysis_result[:delimiter])
    @upload.update!(total_records: rows.count)
    add_detail("Found #{rows.count} records to process")

    # Processar em lotes
    process_rows_in_batches(rows)
  end

  def parse_csv(content, delimiter = ',')
    CSV.parse(content, headers: true, header_converters: :symbol, col_sep: delimiter)
  rescue CSV::MalformedCSVError => e
    raise "Invalid CSV format: #{e.message}"
  end

  def process_rows_in_batches(rows)
    batch_size = 50

    rows.each_slice(batch_size).with_index do |batch, batch_index|
      add_detail("Processing batch #{batch_index + 1} (#{batch.size} records)")
      process_batch(batch, batch_index * batch_size)
      update_progress
    end
  end

  def process_batch(batch, start_index)
    batch.each_with_index do |row, index|
      row_number = start_index + index + 1

      begin
        process_single_row(row, row_number)
        @processed_count += 1
      rescue => e
        @failed_count += 1
        error_message = "Row #{row_number} failed: #{e.message}"
        add_detail(error_message)
        Rails.logger.warn "CSV Import - #{error_message}"
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
    missing_fields = required_fields.select { |field| row[field].blank? }

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
      similar_types = ExamType.where('name ILIKE ?', "%#{test_type}%").limit(3).pluck(:name)
      suggestion = similar_types.any? ? " Similar types: #{similar_types.join(', ')}" : ""
      raise "Exam type not found: #{test_type}.#{suggestion}"
    end

    exam_type
  end

  def find_lab_technician
    if @upload.uploaded_by.lab_technician?
      @upload.uploaded_by
    else
      lab_technician = User.joins(:roles).where(roles: { name: 'lab_technician' }).first
      unless lab_technician
        raise "No lab technician available"
      end
      lab_technician
    end
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

    return existing_request if existing_request

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

  def find_available_doctor
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

  def parse_numeric_value(value)
    parsed = value.to_s.strip.to_f
    if parsed <= 0
      raise "Value must be greater than 0"
    end
    parsed
  end

  def parse_datetime(datetime_str)
    datetime_str = datetime_str.to_s.strip

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

    if row[:notes].present?
      notes << "Original notes: #{row[:notes]}"
    end

    if row[:reference_value].present?
      notes << "Reference value: #{row[:reference_value]}"
    end

    notes.join('. ')
  end

  def sanitize_filename(filename)
    filename.gsub(/[^\w\-.]/, '_')
  end

  def update_progress
    @upload.update!(
      processed_records: @processed_count,
      failed_records: @failed_count
    )
  end

  def finalize_processing
    total_processed = @processed_count + @failed_count
    success_rate = @upload.total_records > 0 ? ((@processed_count.to_f / @upload.total_records) * 100).round(2) : 0

    summary = {
      total_records: @upload.total_records,
      processed_records: @processed_count,
      failed_records: @failed_count,
      success_rate: success_rate,
      file_path: @file_path.to_s,
      processing_started_at: @upload.processing_started_at&.iso8601,
      processing_completed_at: Time.current.iso8601,
      details: @processing_details
    }

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

  def fail_upload(error_message)
    @upload.update_columns(
      status: 'failed',
      error_details: error_message,
      processing_summary: {
        error: error_message,
        processed_records: @processed_count,
        failed_records: @failed_count,
        details: @processing_details
      }.to_json
    )
    add_detail(error_message)
  end

  def handle_critical_error(error)
    error_message = "Critical error during CSV processing: #{error.message}"

    @upload.update_columns(
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

  def add_detail(message)
    timestamp = Time.current.iso8601
    detail = {
      timestamp: timestamp,
      message: message
    }

    @processing_details << detail
    Rails.logger.info "CSV Import [#{@upload.id}]: #{message}"
  end
end
