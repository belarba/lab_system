require 'rails_helper'

RSpec.describe ExamResult, type: :model do
  describe 'basic functionality' do
    it { should belong_to(:exam_request) }
    it { should belong_to(:lab_technician).class_name('User') }
    it { should validate_presence_of(:value) }
    it { should validate_presence_of(:performed_at) }
  end

  describe 'automatic status update' do
    it 'marks exam request as completed after creation' do
      exam_request = create(:exam_request, status: 'scheduled')

      expect {
        create(:exam_result, exam_request: exam_request)
      }.to change { exam_request.reload.status }.to('completed')
    end
  end
end
