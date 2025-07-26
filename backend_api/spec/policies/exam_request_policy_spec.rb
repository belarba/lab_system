require 'rails_helper'

RSpec.describe ExamRequestPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:doctor) { create(:user, :doctor) }
  let(:patient) { create(:user, :patient) }
  let(:other_doctor) { create(:user, :doctor) }
  let(:other_patient) { create(:user, :patient) }
  let(:lab_tech) { create(:user, :lab_technician) }
  let(:exam_type) { create(:exam_type) }

  let(:exam_request) do
    create(:exam_request,
           doctor: doctor,
           patient: patient,
           exam_type: exam_type,
           scheduled_date: 1.week.from_now)
  end

  subject { ExamRequestPolicy }

  describe '#index?' do
    it 'allows admin and lab technician' do
      expect(subject.new(admin, ExamRequest).index?).to be true
      expect(subject.new(lab_tech, ExamRequest).index?).to be true
    end

    it 'denies doctors and patients' do
      expect(subject.new(doctor, ExamRequest).index?).to be false
      expect(subject.new(patient, ExamRequest).index?).to be false
    end
  end

  describe '#show?' do
    it 'allows admin' do
      expect(subject.new(admin, exam_request).show?).to be true
    end

    it 'allows the doctor who created the request' do
      expect(subject.new(doctor, exam_request).show?).to be true
    end

    it 'allows the patient of the request' do
      expect(subject.new(patient, exam_request).show?).to be true
    end

    it 'allows lab technicians' do
      expect(subject.new(lab_tech, exam_request).show?).to be true
    end

    it 'denies other doctors and patients' do
      expect(subject.new(other_doctor, exam_request).show?).to be false
      expect(subject.new(other_patient, exam_request).show?).to be false
    end
  end

  describe '#create?' do
    it 'allows doctors and admin' do
      expect(subject.new(doctor, ExamRequest).create?).to be true
      expect(subject.new(admin, ExamRequest).create?).to be true
    end

    it 'denies patients and lab technicians' do
      expect(subject.new(patient, ExamRequest).create?).to be false
      expect(subject.new(lab_tech, ExamRequest).create?).to be false
    end
  end

  describe '#cancel?' do
    context 'with scheduled exam request' do
      it 'allows admin' do
        expect(subject.new(admin, exam_request).cancel?).to be true
      end

      it 'allows the doctor who created it' do
        expect(subject.new(doctor, exam_request).cancel?).to be true
      end

      it 'allows patient if more than 3 hours before' do
        exam_request.update!(scheduled_date: 5.hours.from_now)
        expect(subject.new(patient, exam_request).cancel?).to be true
      end

      it 'denies patient if less than 3 hours before' do
        exam_request.update!(scheduled_date: 2.hours.from_now)
        expect(subject.new(patient, exam_request).cancel?).to be false
      end

      it 'denies other users' do
        expect(subject.new(other_doctor, exam_request).cancel?).to be false
        expect(subject.new(other_patient, exam_request).cancel?).to be false
      end
    end

    context 'with completed exam request' do
      before do
        exam_request.update!(status: 'completed')
        create(:exam_result, exam_request: exam_request)
      end

      it 'denies everyone from canceling completed requests' do
        expect(subject.new(admin, exam_request).cancel?).to be false
        expect(subject.new(doctor, exam_request).cancel?).to be false
        expect(subject.new(patient, exam_request).cancel?).to be false
      end
    end
  end

  describe ExamRequestPolicy::Scope do
    let!(:admin_request) { create(:exam_request, doctor: admin, patient: patient, exam_type: exam_type) }
    let!(:doctor_request) { exam_request }
    let!(:other_doctor_request) { create(:exam_request, doctor: other_doctor, patient: other_patient, exam_type: exam_type) }

    describe '#resolve' do
      context 'as admin' do
        it 'returns all exam requests' do
          scope = ExamRequestPolicy::Scope.new(admin, ExamRequest.all).resolve
          expect(scope).to include(admin_request, doctor_request, other_doctor_request)
        end
      end

      context 'as doctor' do
        it 'returns only their requests' do
          scope = ExamRequestPolicy::Scope.new(doctor, ExamRequest.all).resolve
          expect(scope).to include(doctor_request)
          expect(scope).not_to include(admin_request, other_doctor_request)
        end
      end

      context 'as patient' do
        it 'returns only their requests' do
          scope = ExamRequestPolicy::Scope.new(patient, ExamRequest.all).resolve
          expect(scope).to include(admin_request, doctor_request)
          expect(scope).not_to include(other_doctor_request)
        end
      end

      context 'as lab technician' do
        it 'returns all exam requests' do
          scope = ExamRequestPolicy::Scope.new(lab_tech, ExamRequest.all).resolve
          expect(scope).to include(admin_request, doctor_request, other_doctor_request)
        end
      end
    end
  end
end
