module Groupable
  module UserGroupable
    extend ActiveSupport::Concern

    included do
      has_many :groupable_members, class_name: 'Groupable::Member', foreign_key: 'user_id', dependent: :destroy
      has_many :groupable_groups, through: :groupable_members, source: :group, class_name: 'Groupable::Group'
    end

    # Alias for better semantics
    def groups
      groupable_groups
    end

    def members
      groupable_members
    end
  end
end
