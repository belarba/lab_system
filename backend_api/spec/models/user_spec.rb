require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'basic validations' do
    it { should validate_presence_of(:email) }
    it { should validate_presence_of(:name) }
    it { should have_secure_password }
  end

  describe 'role methods' do
    let(:user) { create(:user) }
    let(:patient_role) { Role.find_by(name: 'patient') }

    it 'correctly identifies user roles' do
      user.roles << patient_role
      expect(user.patient?).to be_truthy
      expect(user.doctor?).to be_falsy
    end
  end

  describe 'exam request permissions' do
    let(:patient) { create(:user, :patient) }
    let(:exam_type) { create(:exam_type) }

    it 'prevents duplicate exam requests within one week' do
      doctor = create(:user, :doctor)

      # Create first request
      ExamRequest.create!(
        patient: patient, doctor: doctor, exam_type: exam_type,
        scheduled_date: 1.week.from_now, status: 'scheduled',
        created_at: 3.days.ago
      )

      expect(patient.can_request_exam?(exam_type)).to be_falsy
    end

    it 'allows exam request after one week' do
      expect(patient.can_request_exam?(exam_type)).to be_truthy
    end
  end

  describe 'cancel permissions' do
    let(:patient) { create(:user, :patient) }
    let(:doctor) { create(:user, :doctor) }
    let(:exam_request) do
      ExamRequest.create!(
        patient: patient, doctor: doctor, exam_type: create(:exam_type),
        scheduled_date: 5.hours.from_now, status: 'scheduled'
      )
    end

    it 'allows patient to cancel if more than 3 hours before' do
      expect(patient.can_cancel_exam_request?(exam_request)).to be_truthy
    end

    it 'prevents patient cancellation within 3 hours' do
      exam_request.update!(scheduled_date: 2.hours.from_now)
      expect(patient.can_cancel_exam_request?(exam_request)).to be_falsy
    end

    it 'allows doctor to cancel anytime' do
      exam_request.update!(scheduled_date: 1.hour.from_now)
      expect(doctor.can_cancel_exam_request?(exam_request)).to be_truthy
    end
  end
end
