# spec/use_cases/admin_spec.rb
require 'rails_helper'

RSpec.describe 'Admin Use Cases', type: :request do
  let(:admin) { create(:user, :admin) }

  describe 'Admin can log in securely' do
    it 'authenticates with valid credentials' do
      post '/api/auth/login', params: {
        email: admin.email,
        password: 'password123'
      }

      expect(response).to have_http_status(:ok)
      expect(json_response['user']['roles']).to include('admin')
    end
  end

  describe 'Admin can manage user accounts and roles' do
    it 'lists all users' do
      get '/api/admin/users', headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      users = json_response['users']
      expect(users.length).to be >= 1 # at least admin
    end

    it 'creates new user with roles' do
      patient_role = Role.find_by(name: 'patient')

      post '/api/admin/users',
           params: {
             user: {
               name: 'New Patient',
               email: 'newpatient@test.com',
               phone: '+351 91 999 9999'
             },
             role_ids: [patient_role.id]
           },
           headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
      expect(json_response['user']['email']).to eq('newpatient@test.com')
      expect(json_response['user']['roles'].first['name']).to eq('patient')
    end

    it 'updates user information' do
      patient = create(:user, :patient)

      put "/api/admin/users/#{patient.id}",
          params: {
            user: { name: 'Updated Name' }
          },
          headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['user']['name']).to eq('Updated Name')
    end

    it 'deletes user account' do
      # Create a separate user to delete (not the admin)
      deletable_user = create(:user, :patient)
      user_id = deletable_user.id

      # Verify user exists before deletion
      expect(User.find(user_id)).to eq(deletable_user)

      delete "/api/admin/users/#{user_id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('User deleted successfully')

      # Verify user is actually deleted by trying to find it
      expect { User.find(user_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'Admin can configure blood work test types' do
    it 'lists exam types' do
      create(:exam_type, name: 'Blood Sugar')

      get '/api/admin/exam_types', headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      exam_types = json_response['exam_types']
      expect(exam_types.first['name']).to eq('Blood Sugar')
    end

    it 'creates new exam type' do
      post '/api/admin/exam_types',
           params: {
             exam_type: {
               name: 'Cholesterol',
               description: 'Total cholesterol test',
               unit: 'mg/dL',
               reference_range: '< 200 mg/dL'
             }
           },
           headers: auth_headers(admin)

      expect(response).to have_http_status(:created)
      expect(json_response['exam_type']['name']).to eq('Cholesterol')
    end

    it 'updates exam type' do
      exam_type = create(:exam_type, name: 'Original Name')

      put "/api/admin/exam_types/#{exam_type.id}",
          params: {
            exam_type: { name: 'Updated Name' }
          },
          headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['exam_type']['name']).to eq('Updated Name')
    end

    it 'deletes exam type when no associated requests' do
      exam_type = create(:exam_type)
      exam_type_id = exam_type.id

      # Verify exam type exists
      expect(ExamType.find(exam_type_id)).to eq(exam_type)

      delete "/api/admin/exam_types/#{exam_type_id}", headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      expect(json_response['message']).to eq('Exam type deleted successfully')

      # Verify exam type is deleted
      expect { ExamType.find(exam_type_id) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe 'Admin can monitor system performance' do
    before do
      # Create some test data for statistics
      patient = create(:user, :patient)
      lab_tech = create(:user, :lab_technician)
      doctor = create(:user, :doctor)
      exam_type = create(:exam_type)

      exam_request = ExamRequest.create!(
        patient: patient, doctor: doctor, exam_type: exam_type,
        scheduled_date: 1.week.ago, status: 'completed'
      )

      ExamResult.create!(
        exam_request: exam_request, lab_technician: lab_tech,
        value: 95.0, unit: 'mg/dL', performed_at: 1.week.ago
      )

      LabFileUpload.create!(
        filename: 'test.csv', file_size: 1024, uploaded_by: lab_tech,
        status: 'completed', total_records: 5, processed_records: 5
      )
    end

    it 'views system statistics' do
      get '/api/admin/stats', headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      stats = json_response['system_stats']

      expect(stats['users']['total']).to be >= 4 # admin, patient, lab_tech, doctor
      expect(stats['exam_requests']['total']).to eq(1)
      expect(stats['exam_results']['total']).to eq(1)
      expect(stats['uploads']['total']).to eq(1)
      expect(stats['exam_types']['total']).to eq(1)
    end

    it 'views available roles' do
      get '/api/admin/roles', headers: auth_headers(admin)

      expect(response).to have_http_status(:ok)
      roles = json_response['roles']
      role_names = roles.map { |r| r['name'] }
      expect(role_names).to include('patient', 'doctor', 'lab_technician', 'admin')
    end
  end
end
