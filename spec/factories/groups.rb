FactoryBot.define do
  factory :groupable_group, class: 'Groupable::Group' do
    sequence(:name) { |n| "Group #{n}" }
    active { true }

    trait :inactive do
      active { false }
    end
  end
end
