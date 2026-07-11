module Groupable
  class Group < ApplicationRecord
    include Groupable::GroupBehavior

    self.table_name = "groupable_groups"

    validates :name, presence: true
  end
end
