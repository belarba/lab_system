require 'rails_helper'

RSpec.describe LabFileUpload, type: :model do
  describe 'basic functionality' do
    it { should belong_to(:uploaded_by).class_name('User') }
    it { should validate_presence_of(:filename) }
  end

  describe 'success rate calculation' do
    it 'calculates correct success rate' do
      upload = create(:lab_file_upload,
                     total_records: 10,
                     processed_records: 8)
      expect(upload.success_rate).to eq(80.0)
    end

    it 'handles zero total records' do
      upload = create(:lab_file_upload, total_records: 0)
      expect(upload.success_rate).to eq(0)
    end
  end

  describe 'processing summary' do
    let(:upload) { create(:lab_file_upload) }

    it 'adds processing details' do
      upload.add_processing_detail('Test message')

      summary = upload.processing_summary_data
      expect(summary['details'].first['message']).to eq('Test message')
    end
  end
end
