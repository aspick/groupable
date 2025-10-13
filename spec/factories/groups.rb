FactoryBot.define do
  factory :groupable_group, class: 'Groupable::Group' do
    sequence(:name) { |n| "Group #{n}" }
    active { true }

    trait :inactive do
      active { false }
    end

    trait :with_auth do
      auth_name { "auth_#{name}" }
      password { "password123" }
    end
  end
end
