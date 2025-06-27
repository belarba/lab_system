require 'rails_helper'

RSpec.describe CsvImportService do
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
  end

  let(:upload) { create(:lab_file_upload, uploaded_by: lab_tech) }

  describe '#process' do
    context 'with valid CSV data' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,Cholesterol,180.0,mg/dL,2025-04-24T09:15:00Z
        CSV
      end

      it 'processes all records successfully' do
        service = CsvImportService.new(upload, csv_content)

        expect { service.process }.to change(ExamResult, :count).by(2)

        upload.reload
        expect(upload.status).to eq('completed')
        expect(upload.total_records).to eq(2)
        expect(upload.processed_records).to eq(2)
        expect(upload.failed_records).to eq(0)
        expect(upload.success_rate).to eq(100.0)
      end

      it 'creates exam requests and results correctly' do
        service = CsvImportService.new(upload, csv_content)
        service.process

        glucose_result = ExamResult.joins(exam_request: :exam_type)
                                   .find_by(exam_types: { name: 'Glucose' })

        expect(glucose_result).to be_present
        expect(glucose_result.value).to eq(95.0)
        expect(glucose_result.unit).to eq('mg/dL')
        expect(glucose_result.lab_technician).to eq(lab_tech)
        expect(glucose_result.exam_request.patient).to eq(patient)
        expect(glucose_result.notes).to include("Imported from CSV upload ##{upload.id}")
      end
    end

    context 'with invalid CSV data' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          nonexistent@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,NonexistentTest,100.0,mg/dL,2025-04-23T08:30:00Z
        CSV
      end

      it 'handles errors gracefully' do
        service = CsvImportService.new(upload, csv_content)

        expect { service.process }.not_to change(ExamResult, :count)

        upload.reload
        expect(upload.status).to eq('failed')  # Mudança aqui
        expect(upload.total_records).to eq(2)
        expect(upload.processed_records).to eq(0)
        expect(upload.failed_records).to eq(2)
        expect(upload.processing_summary_data['details']).to be_present
      end
    end

    context 'with mixed valid and invalid data' do
      let(:csv_content) do
        <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          test@example.com,Glucose,95.0,mg/dL,2025-04-23T08:30:00Z
          nonexistent@example.com,Glucose,100.0,mg/dL,2025-04-23T08:30:00Z
          test@example.com,Cholesterol,180.0,mg/dL,2025-04-24T09:15:00Z
        CSV
      end

      it 'processes valid records and logs errors for invalid ones' do
        service = CsvImportService.new(upload, csv_content)

        expect { service.process }.to change(ExamResult, :count).by(2)

        upload.reload
        expect(upload.status).to eq('completed')
        expect(upload.total_records).to eq(3)
        expect(upload.processed_records).to eq(2)
        expect(upload.failed_records).to eq(1)
        expect(upload.success_rate).to eq(66.67)
      end
    end
  end
end
