FactoryBot.define do
  factory :lab_file_upload do
    sequence(:filename) { |n| "test_upload_#{n}.csv" }
    file_size { 1024 }
    status { 'pending' }
    association :uploaded_by, factory: [:user, :lab_technician]
    total_records { 0 }
    processed_records { 0 }
    failed_records { 0 }

    trait :processing do
      status { 'processing' }
      processed_at { Time.current }
    end

    trait :completed do
      status { 'completed' }
      processed_at { 1.hour.ago }
      total_records { 10 }
      processed_records { 10 }
      failed_records { 0 }
    end

    trait :failed do
      status { 'failed' }
      processed_at { 1.hour.ago }
      total_records { 5 }
      processed_records { 0 }
      failed_records { 5 }
      error_details { 'Processing failed due to invalid data' }
    end

    trait :completed_with_errors do
      status { 'completed' }
      processed_at { 1.hour.ago }
      total_records { 10 }
      processed_records { 8 }
      failed_records { 2 }
    end
  end
end
