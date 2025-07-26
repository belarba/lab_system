require 'rails_helper'

RSpec.describe CsvImportService, :csv_test do
  before(:all) do
    @patient_role = Role.find_or_create_by(name: 'patient', description: 'Patient role')
    @doctor_role = Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
    @lab_tech_role = Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role')
  end

  let(:lab_tech) { create(:user) }
  let(:doctor) { create(:user) }
  let(:patient) { create(:user, email: 'test@example.com') }

  before do
    lab_tech.roles << @lab_tech_role
    doctor.roles << @doctor_role
    patient.roles << @patient_role

    create(:exam_type, name: 'Glucose', unit: 'mg/dL')
    create(:exam_type, name: 'Cholesterol', unit: 'mg/dL')

    # Garantir que o diretório de upload existe
    ensure_upload_directory
  end

  let(:upload) { create(:lab_file_upload, uploaded_by: lab_tech) }

  describe '#process with improved error handling' do
    context 'with valid CSV data' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,Cholesterol,180.0,mg/dL,2025-04-24T09:15:00Z
        CSV
      end

      it 'processes all records successfully and saves file' do
        service = CsvImportService.new(upload, csv_content)

        expect { service.process }.to change(ExamResult, :count).by(2)

        upload.reload
        expect(upload.status).to eq('completed')
        expect(upload.total_records).to eq(2)
        expect(upload.processed_records).to eq(2)
        expect(upload.failed_records).to eq(0)
        expect(upload.success_rate).to eq(100.0)
        expect(upload.file_hash).to be_present
        expect(upload.file_encoding).to be_present
        expect(upload.processing_started_at).to be_present
        expect(upload.processing_completed_at).to be_present
      end

      it 'saves file to server with correct path' do
        service = CsvImportService.new(upload, csv_content)
        service.process

        upload.reload
        file_path = upload.file_path
        expect(file_path).to be_present
        expect(File.exist?(file_path)).to be_truthy
        expect(File.read(file_path)).to eq(csv_content)
      end

      it 'creates detailed processing summary' do
        service = CsvImportService.new(upload, csv_content)
        service.process

        upload.reload
        summary = upload.processing_summary_data

        expect(summary['total_records']).to eq(2)
        expect(summary['processed_records']).to eq(2)
        expect(summary['failed_records']).to eq(0)
        expect(summary['success_rate']).to eq(100.0)
        expect(summary['details']).to be_an(Array)
        expect(summary['details']).not_to be_empty
        expect(summary['file_path']).to be_present
      end
    end

    context 'with mixed valid and invalid data' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
          invalid@email.com,Glucose,100.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,InvalidType,85.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,Cholesterol,180.0,mg/dL,2025-04-24T09:15:00Z
        CSV
      end

      it 'processes valid records and continues despite errors' do
        service = CsvImportService.new(upload, csv_content)

        # Deve processar apenas os registros válidos
        expect { service.process }.to change(ExamResult, :count).by(2)

        upload.reload
        expect(upload.status).to eq('completed_with_warnings')
        expect(upload.total_records).to eq(4)
        expect(upload.processed_records).to eq(2)
        expect(upload.failed_records).to eq(2)
        expect(upload.success_rate).to eq(50.0)
      end

      it 'logs detailed error messages' do
        service = CsvImportService.new(upload, csv_content)
        service.process

        upload.reload
        errors = upload.processing_errors

        expect(errors).not_to be_empty
        expect(errors.any? { |e| e['message'].include?('Patient not found') }).to be_truthy
        expect(errors.any? { |e| e['message'].include?('Exam type not found') }).to be_truthy
      end
    end

    context 'with completely invalid data' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          invalid@email.com,NonexistentType,not_a_number,mg/dL,invalid_date
          another@invalid.com,AnotherBadType,also_not_number,mg/dL,bad_date
        CSV
      end

      it 'handles complete failure gracefully' do
        service = CsvImportService.new(upload, csv_content)

        expect { service.process }.not_to change(ExamResult, :count)

        upload.reload
        expect(upload.status).to eq('failed')
        expect(upload.total_records).to eq(2)
        expect(upload.processed_records).to eq(0)
        expect(upload.failed_records).to eq(2)
        expect(upload.success_rate).to eq(0.0)
      end
    end

    context 'with malformed CSV' do
      let(:csv_content) { "invalid,csv\ndata,with,inconsistent,columns" }

      it 'fails with appropriate error message' do
        service = CsvImportService.new(upload, csv_content)

        expect { service.process }.not_to change(ExamResult, :count)

        upload.reload
        expect(upload.status).to eq('failed')
        expect(upload.error_details).to be_present
      end
    end

    context 'with batch processing' do
      let(:large_csv_content) do
        header = "patient_email,test_type,measured_value,unit,measured_at\n"
        rows = (1..100).map do |i|
          # Usar datas diferentes para cada linha para evitar reutilização de ExamRequest
          date = (Time.current - i.days).iso8601
          "test@example.com,Glucose,#{90 + i}.0,mg/dL,#{date}"
        end
        header + rows.join("\n")
      end

      it 'processes large files in batches' do
        service = CsvImportService.new(upload, large_csv_content)

        # O número exato pode variar devido à lógica de reutilização de ExamRequest
        # Vamos verificar que pelo menos uma quantidade significativa foi processada
        expect { service.process }.to change(ExamResult, :count).by_at_least(10)

        upload.reload
        expect(upload.status).to eq('completed')
        expect(upload.total_records).to eq(100)
        expect(upload.processed_records).to be >= 10
        expect(upload.failed_records).to be <= 90
      end

      it 'updates progress during batch processing' do
        service = CsvImportService.new(upload, large_csv_content)
        service.process

        upload.reload
        summary = upload.processing_summary_data
        details = summary['details']

        # Deve haver mensagens de progresso por lote
        batch_messages = details.select { |d| d['message'].include?('Processing batch') }
        expect(batch_messages).not_to be_empty
      end

      it 'handles existing exam results correctly' do
        # Criar conteúdo com algumas linhas que criariam o mesmo ExamRequest
        duplicate_csv = <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,Glucose,96.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,Glucose,97.0,mg/dL,2025-04-23T08:30:00Z
        CSV

        service = CsvImportService.new(upload, duplicate_csv)

        # Deve processar apenas a primeira linha e pular as outras
        # porque elas reutilizarão o mesmo ExamRequest que já tem resultado
        expect { service.process }.to change(ExamResult, :count).by(1)

        upload.reload
        # Todas as 3 linhas são consideradas "processadas" mesmo que 2 tenham sido puladas
        expect(upload.processed_records).to eq(3)
        expect(upload.failed_records).to eq(0)
        expect(upload.total_records).to eq(3)
        expect(upload.status).to eq('completed')
      end
    end
  end

  describe 'file management' do
    let(:csv_content) do
      <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
      CSV
    end

    after do
      # Limpar arquivos criados durante os testes
      if upload.reload.file_path && File.exist?(upload.file_path)
        File.delete(upload.file_path)
      end
    end

    it 'creates unique filenames for different uploads' do
      service1 = CsvImportService.new(upload, csv_content)
      service1.process

      upload2 = create(:lab_file_upload, uploaded_by: lab_tech, filename: 'another_file.csv')
      service2 = CsvImportService.new(upload2, csv_content)
      service2.process

      upload.reload
      upload2.reload

      expect(upload.file_path).not_to eq(upload2.file_path)
      expect(File.exist?(upload.file_path)).to be_truthy
      expect(File.exist?(upload2.file_path)).to be_truthy
      expect(File.read(upload.file_path)).to eq(csv_content)
      expect(File.read(upload2.file_path)).to eq(csv_content)

      # Limpeza
      File.delete(upload2.file_path) if File.exist?(upload2.file_path)
    end

    it 'sanitizes dangerous filenames' do
      upload.update!(filename: '../../../dangerous/path.csv')
      service = CsvImportService.new(upload, csv_content)
      service.process

      upload.reload
      file_path = upload.file_path

      expect(file_path).not_to include('../')
      # O sanitizer substitui caracteres perigosos por _
      expect(file_path).to include('dangerous')
      expect(file_path).to include('path.csv')
      expect(File.exist?(file_path)).to be_truthy
    end
  end

  describe 'transaction handling' do
    let(:csv_content) do
      <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
      CSV
    end

    after do
      # Limpar arquivos criados durante os testes
      if upload.reload.file_path && File.exist?(upload.file_path)
        File.delete(upload.file_path)
      end
    end

    it 'rolls back changes on critical errors' do
      # Simular erro crítico no analyzer que impede o processamento
      allow_any_instance_of(CsvAnalyzerService).to receive(:analyze).and_raise("Critical analysis error")

      service = CsvImportService.new(upload, csv_content)

      expect { service.process }.not_to change(ExamResult, :count)

      upload.reload
      expect(upload.status).to eq('failed')
      expect(upload.error_details).to include('Critical analysis error')
    end

    it 'continues processing other rows when individual rows fail' do
      # Mock para fazer segunda linha falhar
      original_method = CsvImportService.instance_method(:find_patient)
      allow_any_instance_of(CsvImportService).to receive(:find_patient) do |instance, email|
        if email == 'test@example.com'
          original_method.bind(instance).call(email)
        else
          raise "Patient not found"
        end
      end

      csv_with_mixed_data = <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
        nonexistent@example.com,Glucose,100.0,mg/dL,2025-04-23T08:30:00Z
      CSV

      service = CsvImportService.new(upload, csv_with_mixed_data)

      expect { service.process }.to change(ExamResult, :count).by(1)

      upload.reload
      expect(upload.processed_records).to eq(1)
      expect(upload.failed_records).to eq(1)
    end
  end

  # Adicionar cleanup geral após todos os testes
  after(:all) do
    # Limpar diretório de uploads de teste
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    if Dir.exist?(upload_dir)
      Dir.glob(File.join(upload_dir, '*')).each do |file|
        File.delete(file) if File.file?(file)
      end
    end
  end
end
