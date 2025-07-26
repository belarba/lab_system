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
    FileUtils.mkdir_p(Rails.root.join('storage', 'uploads', 'csv_files'))
  end

  after do
    # Cleanup files created during tests
    upload_dir = Rails.root.join('storage', 'uploads', 'csv_files')
    Dir.glob(File.join(upload_dir, '*')).each do |file|
      File.delete(file) if File.file?(file)
    end
  end

  describe 'CSV Import with complete mocks' do
    it 'processes valid CSV with all dependencies mocked' do
      csv_content = <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
      CSV

      upload = create(:lab_file_upload, uploaded_by: lab_tech)

      # Garantir que todas as dependências existem
      expect(patient).to be_persisted
      expect(patient.roles.pluck(:name)).to include('patient')
      expect(doctor).to be_persisted
      expect(doctor.roles.pluck(:name)).to include('doctor')
      expect(ExamType.find_by(name: 'Glucose')).to be_present

      service = CsvImportService.new(upload, csv_content)

      # Debug: vamos ver o que acontece durante o processamento
      expect { service.process }.to change(ExamResult, :count).by(1)

      upload.reload
      expect(upload.status).to eq('completed')
      expect(upload.processed_records).to eq(1)
      expect(upload.failed_records).to eq(0)

      # Verificar se o ExamResult foi criado corretamente
      result = ExamResult.last
      expect(result.value).to eq(95.0)
      expect(result.unit).to eq('mg/dL')
      expect(result.lab_technician).to eq(lab_tech)
      expect(result.exam_request.patient).to eq(patient)
      expect(result.exam_request.exam_type.name).to eq('Glucose')
    end

    it 'handles validation errors without file operations' do
      csv_content = "invalid,headers\ndata,here"
      upload = create(:lab_file_upload, uploaded_by: lab_tech)
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

      # Garantir que as dependências existem para a primeira linha
      expect(patient).to be_persisted
      expect(patient.roles.pluck(:name)).to include('patient')
      expect(doctor).to be_persisted
      expect(ExamType.find_by(name: 'Glucose')).to be_present

      service = CsvImportService.new(upload, csv_content)

      # Deve processar apenas 1 linha (a primeira que é válida)
      expect { service.process }.to change(ExamResult, :count).by(1)

      upload.reload
      expect(upload.processed_records).to eq(1)
      expect(upload.failed_records).to eq(1)
      expect(upload.status).to be_in(['completed_with_warnings', 'completed'])

      # Verificar que apenas o resultado válido foi criado
      result = ExamResult.last
      expect(result.exam_request.patient).to eq(patient)
      expect(result.value).to eq(95.0)
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
