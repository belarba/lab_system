require 'rails_helper'

RSpec.describe ExamTypePolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:doctor) { create(:user, :doctor) }
  let(:patient) { create(:user, :patient) }
  let(:lab_tech) { create(:user, :lab_technician) }
  let(:exam_type) { create(:exam_type) }

  subject { ExamTypePolicy }

  describe '#index?' do
    it 'allows everyone to view exam types' do
      expect(subject.new(admin, ExamType).index?).to be true
      expect(subject.new(doctor, ExamType).index?).to be true
      expect(subject.new(patient, ExamType).index?).to be true
      expect(subject.new(lab_tech, ExamType).index?).to be true
    end
  end

  describe '#show?' do
    it 'allows everyone to view exam type details' do
      expect(subject.new(admin, exam_type).show?).to be true
      expect(subject.new(doctor, exam_type).show?).to be true
      expect(subject.new(patient, exam_type).show?).to be true
      expect(subject.new(lab_tech, exam_type).show?).to be true
    end
  end

  describe '#create?' do
    it 'allows only admin' do
      expect(subject.new(admin, ExamType).create?).to be true
    end

    it 'denies non-admin users' do
      expect(subject.new(doctor, ExamType).create?).to be false
      expect(subject.new(patient, ExamType).create?).to be false
      expect(subject.new(lab_tech, ExamType).create?).to be false
    end
  end

  describe '#update?' do
    it 'allows only admin' do
      expect(subject.new(admin, exam_type).update?).to be true
    end

    it 'denies non-admin users' do
      expect(subject.new(doctor, exam_type).update?).to be false
      expect(subject.new(patient, exam_type).update?).to be false
      expect(subject.new(lab_tech, exam_type).update?).to be false
    end
  end

  describe '#destroy?' do
    context 'exam type without requests' do
      it 'allows admin to delete' do
        expect(subject.new(admin, exam_type).destroy?).to be true
      end
    end

    context 'exam type with requests' do
      before do
        create(:exam_request, exam_type: exam_type, doctor: doctor, patient: patient)
      end

      it 'denies admin from deleting' do
        expect(subject.new(admin, exam_type).destroy?).to be false
      end
    end

    it 'denies non-admin users' do
      expect(subject.new(doctor, exam_type).destroy?).to be false
      expect(subject.new(patient, exam_type).destroy?).to be false
      expect(subject.new(lab_tech, exam_type).destroy?).to be false
    end
  end
end
