require 'rails_helper'

RSpec.describe 'Doctor Use Cases', type: :request do
  let(:doctor) { create(:user, :doctor) }
  let(:patient1) { create(:user, :patient, name: 'John Doe') }
  let(:patient2) { create(:user, :patient, name: 'Jane Smith') }
  let(:exam_type) { create(:exam_type, :glucose) }
  let(:lab_tech) { create(:user, :lab_technician) }

  describe 'Doctor can log in securely' do
    it 'authenticates with valid credentials' do
      post '/api/auth/login', params: {
        email: doctor.email,
        password: 'password123'
      }

      expect(response).to have_http_status(:ok)
      expect(json_response['user']['roles']).to include('doctor')
    end
  end

  describe 'Doctor can list and filter patients' do
    before do
      # Create exam requests to establish doctor-patient relationships
      ExamRequest.create!(
        patient: patient1, doctor: doctor, exam_type: exam_type,
        scheduled_date: 1.week.from_now, status: 'scheduled'
      )
      ExamRequest.create!(
        patient: patient2, doctor: doctor, exam_type: exam_type,
        scheduled_date: 2.weeks.from_now, status: 'scheduled'
      )
    end

    it 'lists doctor patients' do
      get "/api/doctors/#{doctor.id}/patients", headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      patients = json_response['patients']
      expect(patients).to have(2).items
      patient_names = patients.map { |p| p['name'] }
      expect(patient_names).to contain_exactly('John Doe', 'Jane Smith')
    end

    it 'filters patients by search term' do
      get "/api/doctors/#{doctor.id}/patients",
          params: { search: 'John' },
          headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      patients = json_response['patients']
      expect(patients).to have(1).item
      expect(patients.first['name']).to eq('John Doe')
    end
  end

  describe 'Doctor can view patient details and blood work' do
    before do
      ExamRequest.create!(
        patient: patient1, doctor: doctor, exam_type: exam_type,
        scheduled_date: 1.week.ago, status: 'completed'
      )
    end

    it 'views patient blood work requests' do
      get "/api/patients/#{patient1.id}/blood_work_requests",
          headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      requests = json_response['blood_work_requests']
      expect(requests).to have(1).item
      expect(requests.first['patient']['id']).to eq(patient1.id)
    end
  end

  describe 'Doctor can create blood work requests for patients' do
    it 'creates blood work request' do
      post '/api/blood_work_requests',
           params: {
             blood_work_request: {
               patient_id: patient1.id,
               exam_type_id: exam_type.id,
               scheduled_date: 1.week.from_now.iso8601,
               notes: 'Routine checkup'
             }
           },
           headers: auth_headers(doctor)

      expect(response).to have_http_status(:created)
      expect(json_response['blood_work_request']['doctor']['id']).to eq(doctor.id)
      expect(json_response['blood_work_request']['patient']['id']).to eq(patient1.id)
    end
  end

  describe 'Doctor can cancel blood work requests' do
    let!(:exam_request) do
      ExamRequest.create!(
        patient: patient1, doctor: doctor, exam_type: exam_type,
        scheduled_date: 1.week.from_now, status: 'scheduled'
      )
    end

    it 'cancels own blood work request' do
      post "/api/blood_work_requests/#{exam_request.id}/cancel",
           headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      expect(json_response['blood_work_request']['status']).to eq('cancelled')
    end
  end

  describe 'Doctor can export patient lab results as CSV' do
    before do
      # Create exam request and result
      exam_request = ExamRequest.create!(
        patient: patient1, doctor: doctor, exam_type: exam_type,
        scheduled_date: 1.week.ago, status: 'completed'
      )
      ExamResult.create!(
        exam_request: exam_request, lab_technician: lab_tech,
        value: 95.0, unit: 'mg/dL', performed_at: 1.week.ago
      )
    end

    it 'exports patient results as CSV data' do
      get "/api/doctors/#{doctor.id}/export/patient/#{patient1.id}",
          headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      expect(json_response['csv_data']).to include('95.0')
      expect(json_response['csv_data']).to include(patient1.name)
      expect(json_response['results_count']).to eq(1)
    end

    it 'exports all patient results' do
      get "/api/doctors/#{doctor.id}/export/all",
          headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      expect(json_response['csv_data']).to include('95.0')
      expect(json_response['results_count']).to eq(1)
    end

    it 'filters export by exam type' do
      get "/api/doctors/#{doctor.id}/export/all",
          params: { exam_type_id: exam_type.id },
          headers: auth_headers(doctor)

      expect(response).to have_http_status(:ok)
      expect(json_response['results_count']).to eq(1)
    end
  end
end
