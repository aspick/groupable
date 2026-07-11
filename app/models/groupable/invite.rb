module Groupable
  class Invite < ApplicationRecord
    self.table_name = "groupable_invites"

    belongs_to :group, class_name: Groupable.configuration.group_class_name

    scope :where_active_invite, ->(code) do
      where(code: code)
        .where(created_at: Groupable.configuration.invite_expiry_days.days.ago..)
    end

    after_initialize :initialize_code

    # Get expiration datetime for this invite
    # @return [ActiveSupport::TimeWithZone] expiration datetime
    def expired_at
      created_at + Groupable.configuration.invite_expiry_days.days
    end

    private

    def initialize_code
      self.code ||= SecureRandom.alphanumeric
    end
  end
end
