require 'rails_helper'

RSpec.describe ExamRequest, type: :model do
  describe 'basic functionality' do
    it { should belong_to(:patient).class_name('User') }
    it { should belong_to(:doctor).class_name('User') }
    it { should belong_to(:exam_type) }
    it { should have_one(:exam_result) }
  end

  describe 'status management' do
    let(:exam_request) { create(:exam_request, status: 'scheduled') }

    it 'marks as completed only when result exists' do
      expect(exam_request.completed?).to be_falsy

      exam_request.update!(status: 'completed')
      expect(exam_request.completed?).to be_falsy

      create(:exam_result, exam_request: exam_request)
      expect(exam_request.completed?).to be_truthy
    end
  end
end
