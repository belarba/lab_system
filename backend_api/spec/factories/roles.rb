FactoryBot.define do
  factory :role do
    sequence(:name) { |n| "role_#{n}" }
    description { "Test role description" }

    trait :patient do
      name { 'patient' }
      description { 'Patient role' }
    end

    trait :doctor do
      name { 'doctor' }
      description { 'Doctor role' }
    end

    trait :lab_technician do
      name { 'lab_technician' }
      description { 'Lab technician role' }
    end

    trait :admin do
      name { 'admin' }
      description { 'Admin role' }
    end
  end
end
