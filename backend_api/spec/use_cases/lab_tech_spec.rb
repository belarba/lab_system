require 'rails_helper'

RSpec.describe 'Lab Technician Use Cases', type: :request do
  let(:lab_tech) { create(:user, :lab_technician) }
  let(:patient) { create(:user, :patient) }
  let(:doctor) { create(:user, :doctor) }

  describe 'Lab Technician can log in securely' do
    it 'authenticates with valid credentials' do
      post '/api/auth/login', params: {
        email: lab_tech.email,
        password: 'password123'
      }

      expect(response).to have_http_status(:ok)
      expect(json_response['user']['roles']).to include('lab_technician')
    end
  end

  describe 'Lab Technician can upload CSV/XLSX files' do
    before do
      # Setup ALL required data for CSV processing
      create(:exam_type, name: 'Glucose', unit: 'mg/dL')

      # Ensure we have a doctor available for auto-assignment
      doctor # This creates the doctor
    end

    def create_csv_file(content)
      file = Tempfile.new(['test', '.csv'])
      file.write(content)
      file.rewind
      Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: 'test.csv')
    end

    it 'uploads valid CSV file' do
      csv_content = <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        #{patient.email},Glucose,95.0,mg/dL,#{2.days.ago.iso8601}
      CSV

      file = create_csv_file(csv_content)

      post '/api/uploads',
           params: { file: file },
           headers: auth_headers(lab_tech)

      expect(response).to have_http_status(:created)

      # Check if processing was successful
      upload = json_response['upload']

      if upload['status'] == 'failed'
        # Debug the failure
        puts "Upload failed. Details:"
        puts "Total records: #{upload['total_records']}"
        puts "Processed: #{upload['processed_records']}"
        puts "Failed: #{upload['failed_records']}"

        # Get upload details to see what went wrong
        upload_id = upload['id']
        get "/api/uploads/#{upload_id}", headers: auth_headers(lab_tech)
        details = json_response['upload']
        puts "Error details: #{details['error_details']}"
      end

      expect(upload['status']).to eq('completed')
      expect(upload['processed_records']).to eq(1)
    end

    it 'handles invalid CSV data gracefully' do
      invalid_csv = <<~CSV
        patient_email,test_type,measured_value,unit,measured_at
        invalid@email.com,Glucose,95.0,mg/dL,#{2.days.ago.iso8601}
      CSV

      file = create_csv_file(invalid_csv)

      post '/api/uploads',
           params: { file: file },
           headers: auth_headers(lab_tech)

      expect(response).to have_http_status(:created)
      upload = json_response['upload']
      expect(upload['failed_records']).to eq(1)
      expect(upload['processed_records']).to eq(0)
    end
  end

  describe 'Lab Technician can track uploaded files and review errors' do
    let!(:completed_upload) do
      LabFileUpload.create!(
        filename: 'results.csv',
        file_size: 1024,
        uploaded_by: lab_tech,
        status: 'completed',
        total_records: 10,
        processed_records: 8,
        failed_records: 2
      )
    end

    it 'lists uploaded files' do
      get '/api/uploads', headers: auth_headers(lab_tech)

      expect(response).to have_http_status(:ok)
      uploads = json_response['uploads']
      expect(uploads.length).to eq(1)
      expect(uploads.first['filename']).to eq('results.csv')
      expect(uploads.first['success_rate']).to eq(80.0)
    end

    it 'views upload details and errors' do
      get "/api/uploads/#{completed_upload.id}", headers: auth_headers(lab_tech)

      expect(response).to have_http_status(:ok)
      upload = json_response['upload']
      expect(upload['processed_records']).to eq(8)
      expect(upload['failed_records']).to eq(2)
    end
  end
end
