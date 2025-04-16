FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    token_version { 1 }
    role { "player" }

    trait :admin do
      role { "admin" }
    end

    trait :with_old_version do
      after(:create) do |user|
        user.update!(token_version: user.token_version + 1)
      end
    end

    trait :privileged_to_unprivileged do
      before(:create) do |user|
        user.role = "admin"
      end
    
      after(:create) do |user|
        user.update!(role: "player")
      end
    end

    trait :unprivileged_to_privileged do
      before(:create) do |user|
        user.role = "player"
      end

      after(:create) do |user|
        user.update!(role: "admin")
      end
    end
  end
end
