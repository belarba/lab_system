class CsvImportService
  require 'csv'

  def initialize(lab_file_upload, file_content)
    @upload = lab_file_upload
    @file_content = file_content
    @processed_count = 0
    @failed_count = 0
    @processing_details = []
  end

  def process
    @upload.update!(status: 'processing', processed_at: Time.current)
    add_detail("Started processing CSV file: #{@upload.filename}")

    begin
      rows = parse_csv(@file_content)
      @upload.update!(total_records: rows.count)
      add_detail("Found #{rows.count} records to process")

      process_rows(rows)
      update_final_status

    rescue => e
      @upload.update!(
        status: 'failed',
        error_details: e.message,
        processing_summary: { error: e.message, details: @processing_details }.to_json
      )
      Rails.logger.error "CSV Import failed: #{e.message}"
    end
  end

  private

  def parse_csv(content)
    CSV.parse(content, headers: true, header_converters: :symbol)
  end

  def process_rows(rows)
    rows.each_with_index do |row, index|
      begin
        process_single_row(row, index + 1)
        @processed_count += 1
        @upload.update!(processed_records: @processed_count)

      rescue => e
        @failed_count += 1
        @upload.update!(failed_records: @failed_count)
        add_detail("Row #{index + 1} failed: #{e.message}")
        Rails.logger.warn "Row #{index + 1} processing failed: #{e.message}"
      end
    end
  end

  def process_single_row(row, row_number)
    # Validar dados da linha
    validate_row_data(row, row_number)

    # Encontrar o paciente pelo email
    patient = find_patient(row[:patient_email])

    # Encontrar o tipo de exame
    exam_type = find_exam_type(row[:test_type])

    # Procurar por uma requisição de exame existente ou criar uma nova
    exam_request = find_or_create_exam_request(patient, exam_type, parse_datetime(row[:measured_at]))

    # Encontrar um técnico de laboratório
    lab_technician = find_lab_technician

    # Criar o resultado do exame
    exam_result = ExamResult.create!(
      exam_request: exam_request,
      value: row[:measured_value],
      unit: row[:unit],
      lab_technician: lab_technician,
      performed_at: parse_datetime(row[:measured_at]),
      lab_file_upload: @upload,
      notes: "Imported from CSV upload ##{@upload.id} (row #{row_number})"
    )

    add_detail("Row #{row_number}: Created exam result ##{exam_result.id} for #{patient.email}")
  end

  def validate_row_data(row, row_number)
    required_fields = [:patient_email, :test_type, :measured_value, :unit, :measured_at]

    required_fields.each do |field|
      if row[field].blank?
        raise "Row #{row_number}: Missing required field '#{field}'"
      end
    end

    unless row[:measured_value].is_a?(Numeric) || row[:measured_value].to_s.match?(/^\d+\.?\d*$/)
      raise "Row #{row_number}: Invalid measured_value '#{row[:measured_value]}'"
    end
  end

  def find_patient(email)
    patient = User.joins(:roles)
                  .where(roles: { name: 'patient' })
                  .find_by(email: email)

    unless patient
      raise "Patient not found: #{email}"
    end

    patient
  end

  def find_exam_type(test_type)
    exam_type = ExamType.find_by(name: test_type)
    unless exam_type
      raise "Exam type not found: #{test_type}"
    end

    exam_type
  end

  def find_or_create_exam_request(patient, exam_type, measured_at)
    # Procurar requisição existente próxima à data (±1 dia)
    existing_request = ExamRequest.joins(:patient, :exam_type)
                                  .where(
                                    patient: patient,
                                    exam_type: exam_type,
                                    scheduled_date: (measured_at - 1.day)..(measured_at + 1.day)
                                  )
                                  .where.not(status: 'cancelled')
                                  .first

    if existing_request
      existing_request
    else
      # Criar nova requisição - precisa de um médico
      doctor = find_doctor

      ExamRequest.create!(
        patient: patient,
        doctor: doctor,
        exam_type: exam_type,
        scheduled_date: measured_at,
        status: 'completed',
        notes: "Auto-created from CSV import ##{@upload.id}"
      )
    end
  end

  def find_doctor
    doctor = User.joins(:roles).where(roles: { name: 'doctor' }).first
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
    DateTime.parse(datetime_str.to_s)
  rescue
    raise "Invalid datetime format: #{datetime_str}"
  end

  def add_detail(message)
    @processing_details << {
      timestamp: Time.current.iso8601,
      message: message
    }
  end

  def update_final_status
    total_processed = @processed_count + @failed_count

    summary = {
      total_records: @upload.total_records,
      processed_records: @processed_count,
      failed_records: @failed_count,
      success_rate: @upload.success_rate,
      details: @processing_details
    }

    # Lógica corrigida para status
    if @failed_count.zero?
      # Todos os registros processados com sucesso
      @upload.update!(
        status: 'completed',
        processing_summary: summary.to_json
      )
      add_detail("Processing completed successfully: #{@processed_count}/#{@upload.total_records} records processed")
    elsif @processed_count.zero?
      # Nenhum registro processado com sucesso (todos falharam)
      @upload.update!(
        status: 'failed',
        processing_summary: summary.to_json
      )
      add_detail("Processing failed: #{@failed_count}/#{@upload.total_records} records failed")
    else
      # Processamento parcial (alguns sucessos, algumas falhas)
      @upload.update!(
        status: 'completed',
        processing_summary: summary.to_json
      )
      add_detail("Processing completed with errors: #{@processed_count} successful, #{@failed_count} failed")
    end
  end
end
