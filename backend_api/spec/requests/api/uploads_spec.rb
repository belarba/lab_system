require 'rails_helper'

RSpec.describe 'Api::Uploads', type: :request do
  # Setup básico de roles
  let!(:patient_role) { Role.find_or_create_by(name: 'patient', description: 'Patient role') }
  let!(:doctor_role) { Role.find_or_create_by(name: 'doctor', description: 'Doctor role') }
  let!(:lab_tech_role) { Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role') }
  let!(:admin_role) { Role.find_or_create_by(name: 'admin', description: 'Admin role') }

  # Usuários para testes
  let(:lab_tech) do
    user = create(:user)
    user.roles << lab_tech_role
    user
  end

  let(:patient) do
    user = create(:user)
    user.roles << patient_role
    user
  end

  let(:admin) do
    user = create(:user)
    user.roles << admin_role
    user
  end

  describe 'GET /api/uploads' do
    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get '/api/uploads'
        expect(response.status).to eq(401)
        expect(JSON.parse(response.body)['error']).to eq('Unauthorized')
      end
    end

    context 'with patient authentication' do
      it 'returns 403 forbidden' do
        get '/api/uploads', headers: auth_headers(patient)
        expect(response.status).to eq(403)
        expect(JSON.parse(response.body)['error']).to eq('Forbidden')
      end
    end

    context 'with lab technician authentication' do
      it 'returns empty uploads list' do
        get '/api/uploads', headers: auth_headers(lab_tech)
        expect(response.status).to eq(200)

        data = JSON.parse(response.body)
        expect(data['uploads']).to be_an(Array)
        expect(data['uploads']).to be_empty
        expect(data['pagination']['total']).to eq(0)
      end

      it 'returns uploads when they exist' do
        # Criar um upload de teste
        upload = LabFileUpload.create!(
          filename: 'test.csv',
          file_size: 1000,
          uploaded_by: lab_tech,
          status: 'completed',
          total_records: 5,
          processed_records: 5,
          failed_records: 0
        )

        get '/api/uploads', headers: auth_headers(lab_tech)
        expect(response.status).to eq(200)

        data = JSON.parse(response.body)
        expect(data['uploads'].length).to eq(1)
        expect(data['uploads'][0]['id']).to eq(upload.id)
        expect(data['uploads'][0]['filename']).to eq('test.csv')
      end
    end

    context 'with admin authentication' do
      it 'returns all uploads' do
        # Criar uploads de diferentes usuários
        upload1 = LabFileUpload.create!(
          filename: 'test1.csv',
          file_size: 1000,
          uploaded_by: lab_tech,
          status: 'completed'
        )

        other_lab_tech = create(:user)
        other_lab_tech.roles << lab_tech_role
        upload2 = LabFileUpload.create!(
          filename: 'test2.csv',
          file_size: 2000,
          uploaded_by: other_lab_tech,
          status: 'failed'
        )

        get '/api/uploads', headers: auth_headers(admin)
        expect(response.status).to eq(200)

        data = JSON.parse(response.body)
        expect(data['uploads'].length).to eq(2)
      end
    end
  end

  describe 'GET /api/uploads/:id' do
    let(:upload) do
      LabFileUpload.create!(
        filename: 'test.csv',
        file_size: 1000,
        uploaded_by: lab_tech,
        status: 'completed',
        total_records: 3,
        processed_records: 2,
        failed_records: 1
      )
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        get "/api/uploads/#{upload.id}"
        expect(response.status).to eq(401)
      end
    end

    context 'as upload owner' do
      it 'returns upload details' do
        get "/api/uploads/#{upload.id}", headers: auth_headers(lab_tech)
        expect(response.status).to eq(200)

        data = JSON.parse(response.body)
        expect(data['upload']['id']).to eq(upload.id)
        expect(data['upload']['filename']).to eq('test.csv')
        expect(data['upload']['total_records']).to eq(3)
        expect(data['upload']['processed_records']).to eq(2)
        expect(data['upload']['failed_records']).to eq(1)
      end
    end

    context 'as different user' do
      it 'returns 403 forbidden' do
        other_user = create(:user)
        other_user.roles << lab_tech_role

        get "/api/uploads/#{upload.id}", headers: auth_headers(other_user)
        expect(response.status).to eq(403)
      end
    end

    context 'as admin' do
      it 'returns upload details' do
        get "/api/uploads/#{upload.id}", headers: auth_headers(admin)
        expect(response.status).to eq(200)

        data = JSON.parse(response.body)
        expect(data['upload']['id']).to eq(upload.id)
      end
    end

    context 'with non-existent upload' do
      it 'returns 404 not found' do
        get '/api/uploads/999999', headers: auth_headers(lab_tech)
        expect(response.status).to eq(404)
        expect(JSON.parse(response.body)['error']).to eq('Upload not found')
      end
    end
  end

  describe 'POST /api/uploads' do
    def create_csv_file(content, filename = 'test.csv')
      file = Tempfile.new([filename.gsub('.csv', ''), '.csv'])
      file.write(content)
      file.rewind

      Rack::Test::UploadedFile.new(file.path, 'text/csv', original_filename: filename)
    end

    context 'without authentication' do
      it 'returns 401 unauthorized' do
        file = create_csv_file("header\ndata")
        post '/api/uploads', params: { file: file }
        expect(response.status).to eq(401)
      end
    end

    context 'as patient' do
      it 'returns 403 forbidden' do
        file = create_csv_file("header\ndata")
        post '/api/uploads', params: { file: file }, headers: auth_headers(patient)
        expect(response.status).to eq(403)
      end
    end

    context 'as lab technician' do
      it 'returns 400 when no file provided' do
        post '/api/uploads', headers: auth_headers(lab_tech)
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']).to eq('File is required')
      end

      it 'returns 400 for non-CSV file' do
        file = Tempfile.new(['test', '.txt'])
        file.write('not csv content')
        file.rewind

        uploaded_file = Rack::Test::UploadedFile.new(file.path, 'text/plain', original_filename: 'test.txt')

        post '/api/uploads', params: { file: uploaded_file }, headers: auth_headers(lab_tech)
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']).to eq('Only CSV files are allowed')
      end

      it 'returns 400 for empty file' do
        file = create_csv_file("")
        post '/api/uploads', params: { file: file }, headers: auth_headers(lab_tech)
        expect(response.status).to eq(400)
        expect(JSON.parse(response.body)['error']).to eq('File is empty')
      end

      context 'with valid CSV processing setup' do
        before do
          # Criar dados necessários para processamento bem-sucedido
          @doctor = create(:user)
          @doctor.roles << doctor_role

          @test_patient = create(:user, email: 'patient@test.com')
          @test_patient.roles << patient_role

          @glucose_type = create(:exam_type, name: 'Glucose', unit: 'mg/dL')
        end

        it 'successfully processes valid CSV' do
          csv_content = <<~CSV
            patient_email,test_type,measured_value,unit,measured_at
            patient@test.com,Glucose,95.5,mg/dL,2025-04-23T08:30:00Z
          CSV

          file = create_csv_file(csv_content)

          expect {
            post '/api/uploads', params: { file: file }, headers: auth_headers(lab_tech)
          }.to change(LabFileUpload, :count).by(1)
           .and change(ExamResult, :count).by(1)

          expect(response.status).to eq(201)

          data = JSON.parse(response.body)
          expect(data['message']).to eq('File uploaded and processed successfully')
          expect(data['upload']['status']).to eq('completed')
          expect(data['upload']['total_records']).to eq(1)
          expect(data['upload']['processed_records']).to eq(1)
          expect(data['upload']['failed_records']).to eq(0)
          expect(data['upload']['success_rate']).to eq(100.0)

          # Verificar se ExamResult foi criado corretamente
          upload = LabFileUpload.last
          result = ExamResult.find_by(lab_file_upload: upload)
          expect(result).to be_present
          expect(result.value).to eq(95.5)
          expect(result.unit).to eq('mg/dL')
          expect(result.lab_technician).to eq(lab_tech)
        end

        it 'handles CSV with invalid data' do
          csv_content = <<~CSV
            patient_email,test_type,measured_value,unit,measured_at
            nonexistent@test.com,Glucose,95.5,mg/dL,2025-04-23T08:30:00Z
          CSV

          file = create_csv_file(csv_content)

          expect {
            post '/api/uploads', params: { file: file }, headers: auth_headers(lab_tech)
          }.to change(LabFileUpload, :count).by(1)
          .and change(ExamResult, :count).by(0)

          expect(response.status).to eq(201)

          data = JSON.parse(response.body)
          upload = LabFileUpload.last
          expect(upload.processed_records).to eq(0)
          expect(upload.failed_records).to eq(1)
          expect(upload.status).to eq('failed')  # Mudança aqui
        end

        it 'handles mixed valid and invalid data' do
          # Criar segundo paciente válido
          @test_patient2 = create(:user, email: 'patient2@test.com')
          @test_patient2.roles << patient_role

          csv_content = <<~CSV
            patient_email,test_type,measured_value,unit,measured_at
            patient@test.com,Glucose,95.5,mg/dL,2025-04-23T08:30:00Z
            nonexistent@test.com,Glucose,100.0,mg/dL,2025-04-23T08:30:00Z
            patient2@test.com,Glucose,88.2,mg/dL,2025-04-23T08:30:00Z
          CSV

          file = create_csv_file(csv_content)

          expect {
            post '/api/uploads', params: { file: file }, headers: auth_headers(lab_tech)
          }.to change(LabFileUpload, :count).by(1)
           .and change(ExamResult, :count).by(2)

          expect(response.status).to eq(201)

          upload = LabFileUpload.last
          expect(upload.total_records).to eq(3)
          expect(upload.processed_records).to eq(2)
          expect(upload.failed_records).to eq(1)
          expect(upload.success_rate).to eq(66.67)
        end
      end
    end

    context 'as admin' do
      before do
        @doctor = create(:user)
        @doctor.roles << doctor_role
        @test_patient = create(:user, email: 'patient@test.com')
        @test_patient.roles << patient_role
        @glucose_type = create(:exam_type, name: 'Glucose', unit: 'mg/dL')
      end

      it 'successfully processes CSV' do
        csv_content = <<~CSV
          patient_email,test_type,measured_value,unit,measured_at
          patient@test.com,Glucose,95.5,mg/dL,2025-04-23T08:30:00Z
        CSV

        file = create_csv_file(csv_content)

        expect {
          post '/api/uploads', params: { file: file }, headers: auth_headers(admin)
        }.to change(LabFileUpload, :count).by(1)

        expect(response.status).to eq(201)

        upload = LabFileUpload.last
        expect(upload.uploaded_by).to eq(admin)
      end
    end
  end
end
