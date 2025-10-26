module Groupable
  class Member < ApplicationRecord
    self.table_name = "groupable_members"

    belongs_to :group,
               class_name: "Groupable::Group",
               foreign_key: :group_id

    belongs_to :user,
               class_name: "User"

    # Default enum - can be overridden via configuration
    enum :role, { member: 1, editor: 2, admin: 3 }

    validates :role, presence: true
    validates :user_id, uniqueness: { scope: :group_id }
  end
end
