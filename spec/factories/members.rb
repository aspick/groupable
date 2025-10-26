FactoryBot.define do
  factory :groupable_member, class: 'Groupable::Member' do
    association :user
    association :group, factory: :groupable_group
    role { :member }

    trait :editor do
      role { :editor }
    end

    trait :admin do
      role { :admin }
    end
  end
end
