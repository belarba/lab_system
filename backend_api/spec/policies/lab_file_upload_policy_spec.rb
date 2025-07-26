require 'rails_helper'

RSpec.describe LabFileUploadPolicy, type: :policy do
  let(:admin) { create(:user, :admin) }
  let(:lab_tech) { create(:user, :lab_technician) }
  let(:other_lab_tech) { create(:user, :lab_technician) }
  let(:doctor) { create(:user, :doctor) }
  let(:patient) { create(:user, :patient) }

  let(:upload) { create(:lab_file_upload, uploaded_by: lab_tech) }
  let(:admin_upload) { create(:lab_file_upload, uploaded_by: admin) }

  subject { LabFileUploadPolicy }

  describe '#index?' do
    it 'allows lab technicians and admin' do
      expect(subject.new(lab_tech, LabFileUpload).index?).to be true
      expect(subject.new(admin, LabFileUpload).index?).to be true
    end

    it 'denies doctors and patients' do
      expect(subject.new(doctor, LabFileUpload).index?).to be false
      expect(subject.new(patient, LabFileUpload).index?).to be false
    end
  end

  describe '#show?' do
    it 'allows admin to view any upload' do
      expect(subject.new(admin, upload).show?).to be true
      expect(subject.new(admin, admin_upload).show?).to be true
    end

    it 'allows upload owner to view their uploads' do
      expect(subject.new(lab_tech, upload).show?).to be true
    end

    it 'denies other lab techs from viewing uploads they did not create' do
      expect(subject.new(other_lab_tech, upload).show?).to be false
    end

    it 'denies doctors and patients' do
      expect(subject.new(doctor, upload).show?).to be false
      expect(subject.new(patient, upload).show?).to be false
    end
  end

  describe '#create?' do
    it 'allows lab technicians and admin' do
      expect(subject.new(lab_tech, LabFileUpload).create?).to be true
      expect(subject.new(admin, LabFileUpload).create?).to be true
    end

    it 'denies doctors and patients' do
      expect(subject.new(doctor, LabFileUpload).create?).to be false
      expect(subject.new(patient, LabFileUpload).create?).to be false
    end
  end

  describe LabFileUploadPolicy::Scope do
    let!(:lab_tech_upload) { upload }
    let!(:other_lab_tech_upload) { create(:lab_file_upload, uploaded_by: other_lab_tech) }
    let!(:admin_upload_record) { admin_upload }

    describe '#resolve' do
      context 'as admin' do
        it 'returns all uploads' do
          scope = LabFileUploadPolicy::Scope.new(admin, LabFileUpload.all).resolve
          expect(scope).to include(lab_tech_upload, other_lab_tech_upload, admin_upload_record)
        end
      end

      context 'as lab technician' do
        it 'returns only their uploads' do
          scope = LabFileUploadPolicy::Scope.new(lab_tech, LabFileUpload.all).resolve
          expect(scope).to include(lab_tech_upload)
          expect(scope).not_to include(other_lab_tech_upload, admin_upload_record)
        end
      end

      context 'as non-authorized user' do
        it 'returns no uploads for patient' do
          scope = LabFileUploadPolicy::Scope.new(patient, LabFileUpload.all).resolve
          expect(scope).to be_empty
        end

        it 'returns no uploads for doctor' do
          scope = LabFileUploadPolicy::Scope.new(doctor, LabFileUpload.all).resolve
          expect(scope).to be_empty
        end
      end
    end
  end
end
