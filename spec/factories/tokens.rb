FactoryBot.define do
  factory :token do
    user
    jti { Token.generate_jti }
    token_type { "access" }
    expires_at { 15.minutes.from_now }

    trait :refresh do
      token_type { "refresh" }
      expires_at { 7.days.from_now }
    end

    trait :expired do
      expires_at { 1.minute.ago }
    end
  end
end
