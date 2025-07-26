require 'rails_helper'

RSpec.describe UserPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:doctor) { create(:user, :doctor) }
  let(:patient) { create(:user, :patient) }
  let(:other_patient) { create(:user, :patient) }
  let(:lab_tech) { create(:user, :lab_technician) }

  subject { UserPolicy }

  describe '#index?' do
    context 'when user is admin' do
      it 'returns true' do
        expect(subject.new(admin, User).index?).to be true
      end
    end

    context 'when user is not admin' do
      it 'returns false for doctor' do
        expect(subject.new(doctor, User).index?).to be false
      end

      it 'returns false for patient' do
        expect(subject.new(patient, User).index?).to be false
      end

      it 'returns false for lab technician' do
        expect(subject.new(lab_tech, User).index?).to be false
      end
    end
  end

  describe '#show?' do
    context 'when user is admin' do
      it 'can view any user' do
        expect(subject.new(admin, patient).show?).to be true
        expect(subject.new(admin, doctor).show?).to be true
      end
    end

    context 'when viewing own profile' do
      it 'allows user to view themselves' do
        expect(subject.new(patient, patient).show?).to be true
        expect(subject.new(doctor, doctor).show?).to be true
      end
    end

    context 'when viewing other users' do
      it 'denies access to unrelated users' do
        expect(subject.new(patient, other_patient).show?).to be false
        expect(subject.new(other_patient, patient).show?).to be false
      end
    end

    context 'with doctor-patient relationship' do
      before do
        exam_type = create(:exam_type)
        create(:exam_request, doctor: doctor, patient: patient, exam_type: exam_type)
      end

      it 'allows doctor to view their patients' do
        expect(subject.new(doctor, patient).show?).to be true
      end

      it 'allows patient to view their doctors' do
        expect(subject.new(patient, doctor).show?).to be true
      end
    end

    context 'with lab technician' do
      it 'allows lab tech to view patients' do
        expect(subject.new(lab_tech, patient).show?).to be true
      end

      it 'denies lab tech from viewing doctors' do
        expect(subject.new(lab_tech, doctor).show?).to be false
      end
    end
  end

  describe '#create?' do
    it 'allows admin to create users' do
      expect(subject.new(admin, User).create?).to be true
    end

    it 'denies non-admin from creating users' do
      expect(subject.new(patient, User).create?).to be false
      expect(subject.new(doctor, User).create?).to be false
      expect(subject.new(lab_tech, User).create?).to be false
    end
  end

  describe '#update?' do
    it 'allows admin to update any user' do
      expect(subject.new(admin, patient).update?).to be true
    end

    it 'allows user to update themselves' do
      expect(subject.new(patient, patient).update?).to be true
    end

    it 'denies user from updating others' do
      expect(subject.new(patient, other_patient).update?).to be false
    end
  end

  describe '#destroy?' do
    it 'allows admin to delete other users' do
      expect(subject.new(admin, patient).destroy?).to be true
    end

    it 'prevents admin from deleting themselves' do
      expect(subject.new(admin, admin).destroy?).to be false
    end

    it 'denies non-admin from deleting users' do
      expect(subject.new(patient, other_patient).destroy?).to be false
      expect(subject.new(doctor, patient).destroy?).to be false
    end
  end

  describe '#me?' do
    it 'allows any authenticated user' do
      expect(subject.new(admin, admin).me?).to be true
      expect(subject.new(patient, patient).me?).to be true
      expect(subject.new(doctor, doctor).me?).to be true
    end
  end

  describe UserPolicy::Scope do
    describe '#resolve' do
      context 'as admin' do
        it 'returns all users' do
          scope = UserPolicy::Scope.new(admin, User.all).resolve
          expect(scope).to include(admin, patient, doctor)
        end
      end

      context 'as non-admin' do
        it 'returns only the user themselves' do
          scope = UserPolicy::Scope.new(patient, User.all).resolve
          expect(scope.to_a).to eq([patient])
        end
      end
    end
  end
end
