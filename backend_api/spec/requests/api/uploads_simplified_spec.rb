require 'rails_helper'

RSpec.describe 'Api::Uploads', type: :request do
  before(:all) do
    Role.find_or_create_by(name: 'patient', description: 'Patient role')
    Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
    Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role')
    Role.find_or_create_by(name: 'admin', description: 'Admin role')
  end

  let(:patient_role) { Role.find_by(name: 'patient') }
  let(:lab_tech_role) { Role.find_by(name: 'lab_technician') }
  let(:admin_role) { Role.find_by(name: 'admin') }

  describe 'GET /api/uploads' do
    it 'returns unauthorized without token' do
      get '/api/uploads'
      expect(response).to have_http_status(:unauthorized)
      expect(json_response['error']).to eq('Unauthorized')
    end

    it 'returns forbidden for patient role' do
      patient = create(:user)
      patient.roles << patient_role

      get '/api/uploads', headers: auth_headers(patient)
      expect(response).to have_http_status(:forbidden)
      expect(json_response['error']).to eq('Forbidden')
    end

    it 'returns empty list for lab technician' do
      lab_tech = create(:user)
      lab_tech.roles << lab_tech_role

      get '/api/uploads', headers: auth_headers(lab_tech)
      expect(response).to have_http_status(:ok)

      response_data = json_response
      expect(response_data['uploads']).to be_an(Array)
      expect(response_data['uploads']).to be_empty
      expect(response_data['pagination']).to include(
        'limit' => 50,
        'offset' => 0,
        'total' => 0
      )
    end
  end

  describe 'POST /api/uploads' do
    let(:lab_tech) do
      user = create(:user)
      user.roles << lab_tech_role
      user
    end

    def create_csv_file(content, filename = 'test.csv')
      file = Tempfile.new([filename.gsub('.csv', ''), '.csv'])
      file.write(content)
      file.rewind

      Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: filename)
    end

    it 'returns unauthorized without token' do
      file = create_csv_file("test,data\n1,2")
      post '/api/uploads', params: { file: file }
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns bad request without file' do
      post '/api/uploads', headers: auth_headers(lab_tech)
      expect(response).to have_http_status(:bad_request)
      expect(json_response['error']).to eq('File is required')
    end

    it 'returns bad request for non-CSV file' do
      file = Tempfile.new(['test', '.txt'])
      file.write('not csv content')
      file.rewind

      uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/plain', original_filename: 'test.txt')

      post '/api/uploads', params: { file: uploaded_file }, headers: auth_headers(lab_tech)
      expect(response).to have_http_status(:bad_request)
      expect(json_response['error']).to eq('Only CSV files are allowed')
    end

    context 'with valid setup for CSV processing' do
      before do
        # Criar dados necessários para processamento
        @doctor = create(:user)
        @doctor.roles << Role.find_by(name: 'doctor')

        @patient = create(:user, email: 'test@example.com')
        @patient.roles << patient_role

        @exam_type = create(:exam_type, name: 'TestExam', unit: 'mg/dL')
      end

      it 'processes valid CSV file' do
        csv_content = <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          test@example.com,TestExam,95.0,mg/dL,2025-04-23T08:30:00Z
        CSV

        file = create_csv_file(csv_content)

        expect {
          post '/api/uploads', params: { file: file }, headers: auth_headers(lab_tech)
        }.to change(LabFileUpload, :count).by(1)
         .and change(ExamResult, :count).by(1)

        expect(response).to have_http_status(:created)

        response_data = json_response
        expect(response_data['message']).to eq('File uploaded and processed successfully')
        expect(response_data['upload']).to include(
          'filename' => 'test.csv',
          'status' => 'completed',
          'total_records' => 1,
          'processed_records' => 1,
          'failed_records' => 0
        )
      end

      it 'handles invalid CSV gracefully' do
        csv_content = <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          unknown@example.com,UnknownExam,95.0,mg/dL,2025-04-23T08:30:00Z
        CSV

        file = create_csv_file(csv_content)

        expect {
          post '/api/uploads', params: { file: file }, headers: auth_headers(lab_tech)
        }.to change(LabFileUpload, :count).by(1)
         .and change(ExamResult, :count).by(0)

        expect(response).to have_http_status(:created)

        upload = LabFileUpload.last
        expect(upload.failed_records).to eq(1)
        expect(upload.processed_records).to eq(0)
      end
    end
  end

  describe 'GET /api/uploads/:id' do
    let(:lab_tech) do
      user = create(:user)
      user.roles << lab_tech_role
      user
    end

    let(:upload) do
      LabFileUpload.create!(
        filename: 'test.csv',
        file_size: 1024,
        uploaded_by: lab_tech,
        status: 'completed',
        total_records: 5,
        processed_records: 5,
        failed_records: 0
      )
    end

    it 'returns unauthorized without token' do
      get "/api/uploads/#{upload.id}"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns upload details for owner' do
      get "/api/uploads/#{upload.id}", headers: auth_headers(lab_tech)
      expect(response).to have_http_status(:ok)

      response_data = json_response
      expect(response_data['upload']).to include(
        'id' => upload.id,
        'filename' => 'test.csv',
        'status' => 'completed'
      )
    end

    it 'returns forbidden for different user' do
      other_user = create(:user)
      other_user.roles << lab_tech_role

      get "/api/uploads/#{upload.id}", headers: auth_headers(other_user)
      expect(response).to have_http_status(:forbidden)
    end
  end
end
