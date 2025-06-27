FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    name { Faker::Name.name }
    password { 'password123' }
    password_confirmation { 'password123' }

    trait :patient do
      after(:create) do |user|
        role = Role.find_or_create_by(name: 'patient') do |r|
          r.description = 'Patient role'
        end
        user.roles << role unless user.roles.include?(role)
      end
    end

    trait :doctor do
      after(:create) do |user|
        role = Role.find_or_create_by(name: 'doctor') do |r|
          r.description = 'Doctor role'
        end
        user.roles << role unless user.roles.include?(role)
      end
    end

    trait :lab_technician do
      after(:create) do |user|
        role = Role.find_or_create_by(name: 'lab_technician') do |r|
          r.description = 'Lab technician role'
        end
        user.roles << role unless user.roles.include?(role)
      end
    end

    trait :admin do
      after(:create) do |user|
        role = Role.find_or_create_by(name: 'admin') do |r|
          r.description = 'Admin role'
        end
        user.roles << role unless user.roles.include?(role)
      end
    end
  end
end
