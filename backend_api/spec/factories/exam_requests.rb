FactoryBot.define do
  factory :exam_request do
    association :patient, factory: :user, strategy: :build
    association :doctor, factory: :user, strategy: :build
    association :exam_type
    scheduled_date { 1.week.from_now }
    status { 'scheduled' }
    notes { 'Test exam request' }

    after(:build) do |exam_request|
      # Garantir que patient tem role patient
      patient_role = Role.find_or_create_by(name: 'patient', description: 'Patient role')
      exam_request.patient.roles << patient_role unless exam_request.patient.roles.include?(patient_role)

      # Garantir que doctor tem role doctor
      doctor_role = Role.find_or_create_by(name: 'doctor', description: 'Doctor role')
      exam_request.doctor.roles << doctor_role unless exam_request.doctor.roles.include?(doctor_role)
    end

    trait :pending do
      status { 'pending' }
    end

    trait :completed do
      status { 'completed' }
      after(:create) do |exam_request|
        create(:exam_result, exam_request: exam_request)
      end
    end

    trait :cancelled do
      status { 'cancelled' }
    end
  end
end
