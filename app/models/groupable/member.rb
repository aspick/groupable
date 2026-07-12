module Groupable
  class Member < ApplicationRecord
    include Groupable::MemberBehavior

    self.table_name = "groupable_members"
  end
end
