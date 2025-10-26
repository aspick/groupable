FactoryBot.define do
  factory :groupable_invite, class: 'Groupable::Invite' do
    association :group, factory: :groupable_group

    # code is generated automatically via after_initialize callback

    trait :expired do
      created_at { 31.days.ago }
    end
  end
end
