require 'rails_helper'

RSpec.describe 'Api::BloodWorkRequests', type: :request do
  # Criar roles uma vez antes de todos os testes
  before(:all) do
    @patient_role = Role.find_or_create_by(name: 'patient', description: 'Patient role')
    @doctor_role = Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
    @lab_tech_role = Role.find_or_create_by(name: 'lab_technician', description: 'Lab technician role')
  end

  describe 'POST /api/blood_work_requests' do
    let(:doctor) { create(:user) }
    let(:patient) { create(:user) }
    let(:exam_type) { create(:exam_type, :glucose) }

    before do
      # Garantir que os roles estão associados
      doctor.roles << @doctor_role unless doctor.roles.include?(@doctor_role)
      patient.roles << @patient_role unless patient.roles.include?(@patient_role)
    end

    let(:valid_params) do
      {
        blood_work_request: {
          patient_id: patient.id,
          exam_type_id: exam_type.id,
          scheduled_date: 1.week.from_now.iso8601,
          notes: 'Test exam'
        }
      }
    end

    it 'returns unauthorized without token' do
      post '/api/blood_work_requests', params: valid_params
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized with invalid token' do
      post '/api/blood_work_requests',
           params: valid_params,
           headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns forbidden for patient role' do
      patient_user = create(:user)
      patient_user.roles << @patient_role

      post '/api/blood_work_requests',
           params: valid_params,
           headers: auth_headers(patient_user)

      expect(response).to have_http_status(:forbidden)
    end

    context 'when authenticated as doctor' do
      it 'creates a new blood work request' do
        expect {
          post '/api/blood_work_requests',
               params: valid_params,
               headers: auth_headers(doctor)
        }.to change(ExamRequest, :count).by(1)

        expect(response).to have_http_status(:created)

        response_data = json_response
        expect(response_data['message']).to eq('Blood work request created successfully')
        expect(response_data['blood_work_request']).to include(
          'patient' => hash_including('id' => patient.id),
          'doctor' => hash_including('id' => doctor.id),
          'exam_type' => hash_including('id' => exam_type.id),
          'status' => 'scheduled'
        )
      end

      it 'returns not found with invalid patient' do
        invalid_params = valid_params.dup
        invalid_params[:blood_work_request][:patient_id] = 999999

        post '/api/blood_work_requests',
             params: invalid_params,
             headers: auth_headers(doctor)

        expect(response).to have_http_status(:not_found)

        response_data = json_response
        expect(response_data['error']).to eq('Patient not found') if response_data.present?
      end

      it 'returns not found with invalid exam type' do
        invalid_params = valid_params.dup
        invalid_params[:blood_work_request][:exam_type_id] = 999999

        post '/api/blood_work_requests',
             params: invalid_params,
             headers: auth_headers(doctor)

        expect(response).to have_http_status(:not_found)

        response_data = json_response
        expect(response_data['error']).to eq('Exam type not found') if response_data.present?
      end
    end
  end

  describe 'POST /api/blood_work_requests/:id/cancel' do
    let(:doctor) { create(:user) }
    let(:patient) { create(:user) }

    before do
      doctor.roles << @doctor_role unless doctor.roles.include?(@doctor_role)
      patient.roles << @patient_role unless patient.roles.include?(@patient_role)
    end

    # Criar exam_request manualmente para evitar problemas de factory
    let(:exam_request) do
      exam_type = create(:exam_type)
      ExamRequest.create!(
        doctor: doctor,
        patient: patient,
        exam_type: exam_type,
        scheduled_date: 1.week.from_now,
        status: 'scheduled',
        notes: 'Test exam'
      )
    end

    it 'returns unauthorized without token' do
      post "/api/blood_work_requests/#{exam_request.id}/cancel"
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns unauthorized with invalid token' do
      post "/api/blood_work_requests/#{exam_request.id}/cancel",
           headers: { 'Authorization' => 'Bearer invalid_token' }

      expect(response).to have_http_status(:unauthorized)
    end

    context 'when authenticated as the doctor who created the request' do
      it 'cancels the blood work request' do
        post "/api/blood_work_requests/#{exam_request.id}/cancel",
             headers: auth_headers(doctor)

        expect(response).to have_http_status(:ok)

        response_data = json_response
        expect(response_data['message']).to eq('Blood work request cancelled successfully')
        expect(response_data['blood_work_request']['status']).to eq('cancelled')
        expect(exam_request.reload.status).to eq('cancelled')
      end
    end

    context 'when trying to cancel completed request' do
      it 'returns error' do
        # Criar um ExamResult para marcar como completed
        lab_tech = create(:user)
        lab_tech.roles << @lab_tech_role

        exam_result = ExamResult.create!(
          exam_request: exam_request,
          lab_technician: lab_tech,
          value: 100.0,
          unit: 'mg/dL',
          performed_at: Time.current,
          notes: 'Test result'
        )

        post "/api/blood_work_requests/#{exam_request.id}/cancel",
             headers: auth_headers(doctor)

        expect(response).to have_http_status(:forbidden)

        response_data = json_response
        expect(response_data['error']).to eq('Forbidden') if response_data.present?
      end
    end

    context 'when authenticated as different doctor' do
      it 'returns forbidden' do
        other_doctor = create(:user)
        other_doctor.roles << @doctor_role

        post "/api/blood_work_requests/#{exam_request.id}/cancel",
             headers: auth_headers(other_doctor)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
