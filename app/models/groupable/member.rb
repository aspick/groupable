module Groupable
  class Member < ApplicationRecord
    self.table_name = 'groupable_members'

    belongs_to :group,
               class_name: -> { Groupable.configuration.group_class_name },
               foreign_key: :group_id

    belongs_to :user,
               class_name: -> { Groupable.configuration.user_class_name }

    # Default enum - can be overridden via configuration
    enum :role, { member: 1, editor: 2, admin: 3 }

    validates :role, presence: true
    validates :user_id, uniqueness: { scope: :group_id }
  end
end
