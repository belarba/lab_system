FactoryBot.define do
  factory :exam_result do
    association :exam_request
    association :lab_technician, factory: [:user, :lab_technician]
    value { 150.5 }
    unit { 'mg/dL' }
    performed_at { Time.current }
    notes { 'Test result' }
  end
end
