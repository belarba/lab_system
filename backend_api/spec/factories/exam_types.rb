FactoryBot.define do
  factory :exam_type do
    sequence(:name) { |n| "Exam Type #{n}" }
    unit { 'mg/dL' }
    reference_range { '< 200 mg/dL' }
    description { 'Test exam type' }

    trait :glucose do
      name { 'Glucose' }
      unit { 'mg/dL' }
      reference_range { '70-99 mg/dL' }
    end

    trait :cholesterol do
      name { 'Cholesterol' }
      unit { 'mg/dL' }
      reference_range { '< 200 mg/dL' }
    end
  end
end
