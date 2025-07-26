require 'rails_helper'

RSpec.describe 'Basic CSV Import Test' do
  before(:all) do
    Role.find_or_create_by(name: 'patient', description: 'Patient role')
    Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
    Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role')
  end

  let(:lab_tech) { create(:user, :lab_technician) }
  let(:patient) { create(:user, :patient, email: 'test@example.com') }
  let(:doctor) { create(:user, :doctor) }

  before do
    create(:exam_type, name: 'Glucose', unit: 'mg/dL')

    # Criar diretório se não existir
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    FileUtils.mkdir_p(upload_dir) unless Dir.exist?(upload_dir)
  end

  describe 'CSV Import with complete mocks' do
    it 'processes valid CSV with all dependencies mocked' do
      csv_content = <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
      CSV

      upload = create(:lab_file_upload, uploaded_by: lab_tech)

      # Mock completo do analyzer
      analyzer = double('CsvAnalyzerService',
        analyze: nil,
        valid_for_import?: true,
        validation_errors: [],
        analysis_result: {
          file_hash: 'test-hash',
          encoding: 'UTF-8',
          delimiter: ',',
          headers: ['patient_email', 'test_type', 'measured_value', 'unit', 'measured_at']
        }
      )

      allow(CsvAnalyzerService).to receive(:new).and_return(analyzer)

      # Mock do salvamento de arquivo para evitar dependências de sistema de arquivos
      allow_any_instance_of(CsvImportService).to receive(:save_file_to_server).and_return('/mock/path/file.csv')

      service = CsvImportService.new(upload, csv_content)

      expect { service.process }.to change(ExamResult, :count).by(1)

      upload.reload
      expect(upload.status).to be_in(['completed', 'completed_with_warnings'])
      expect(upload.processed_records).to be >= 1
    end

    it 'handles validation errors without file operations' do
      csv_content = "invalid,headers\ndata,here"
      upload = create(:lab_file_upload, uploaded_by: lab_tech)

      # Mock analyzer que retorna erro de validação
      analyzer = double('CsvAnalyzerService',
        analyze: nil,
        valid_for_import?: false,
        validation_errors: ['Missing required headers: patient_email, test_type']
      )

      allow(CsvAnalyzerService).to receive(:new).and_return(analyzer)

      service = CsvImportService.new(upload, csv_content)

      expect { service.process }.not_to change(ExamResult, :count)

      upload.reload
      expect(upload.status).to eq('failed')
      expect(upload.error_details).to include('File validation failed')
    end

    it 'handles individual row processing errors' do
      csv_content = <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
        nonexistent@example.com,Glucose,100.0,mg/dL,2025-04-23T08:30:00Z
      CSV

      upload = create(:lab_file_upload, uploaded_by: lab_tech)

      # Mock analyzer
      analyzer = double('CsvAnalyzerService',
        analyze: nil,
        valid_for_import?: true,
        validation_errors: [],
        analysis_result: {
          file_hash: 'test-hash',
          encoding: 'UTF-8',
          delimiter: ',',
          headers: ['patient_email', 'test_type', 'measured_value', 'unit', 'measured_at']
        }
      )

      allow(CsvAnalyzerService).to receive(:new).and_return(analyzer)
      allow_any_instance_of(CsvImportService).to receive(:save_file_to_server).and_return('/mock/path/file.csv')

      service = CsvImportService.new(upload, csv_content)

      # Deve processar apenas 1 linha (a primeira que é válida)
      expect { service.process }.to change(ExamResult, :count).by(1)

      upload.reload
      expect(upload.processed_records).to eq(1)
      expect(upload.failed_records).to eq(1)
      expect(upload.status).to be_in(['completed_with_warnings', 'completed'])
    end
  end

  describe 'LabFileUpload model methods' do
    let(:upload) { create(:lab_file_upload, uploaded_by: lab_tech) }

    it 'calculates success rate correctly' do
      upload.update!(total_records: 10, processed_records: 8, failed_records: 2)
      expect(upload.success_rate).to eq(80.0)
    end

    it 'has correct status checking methods' do
      upload.update!(status: 'completed')
      expect(upload.completed?).to be_truthy
      expect(upload.failed?).to be_falsy

      upload.update!(status: 'failed')
      expect(upload.completed?).to be_falsy
      expect(upload.failed?).to be_truthy
    end

    it 'formats file size correctly' do
      upload.update!(file_size: 1024)
      expect(upload.file_size_human).to eq('1.0 KB')

      upload.update!(file_size: 1048576)
      expect(upload.file_size_human).to eq('1.0 MB')
    end
  end
end
