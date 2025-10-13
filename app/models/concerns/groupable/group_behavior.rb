module Groupable
  module GroupBehavior
    extend ActiveSupport::Concern

    included do
      # Use configured member class for associations
      has_many :groupable_members,
               -> { extending GroupableMembersExtension },
               class_name: 'Groupable::Member',
               foreign_key: :group_id,
               dependent: :destroy

      has_many :groupable_users,
               through: :groupable_members,
               source: :user

      # Alias for better semantics
      alias_method :members, :groupable_members unless method_defined?(:members)
      alias_method :users, :groupable_users unless method_defined?(:users)
    end

    module GroupableMembersExtension
      # Extension methods for groupable_members association
    end

    # Check if user has joined this group
    # @param [Object] user - User object
    # @return [Boolean] joined
    def joined?(user)
      groupable_users.include?(user)
    end

    # Add user to this group
    # @param [Object] user - User object
    # @param [Symbol] role - Role for the user (:member, :editor, :admin)
    # @return [Member] created member
    def join!(user, role = nil)
      role ||= Groupable.configuration.default_role
      raise ArgumentError, 'user does not exist' unless user
      raise ArgumentError, 'user is already joined' if joined?(user)

      groupable_members.create!(user: user, role: role)
    end

    # Get member record for user
    # @param [Object] user - User object
    # @return [Member, nil] member
    def member_of_user(user)
      groupable_members.find { |member| member.user_id == user.id }
    end

    # Get editor and admin members
    # @return [ActiveRecord::Relation] members with editor or admin role
    def editor_members
      member_class = Groupable.configuration.member_class
      groupable_members.where(
        role: [member_class.roles[:editor], member_class.roles[:admin]]
      )
    end

    class_methods do
      # Create new group on user initiated flow
      # Initiated user will be admin of the group.
      # @param [String] name - Group name
      # @param [Object] user - User object
      # @param [Hash] options - Additional options
      # @return [Group] created group
      def create_new_group!(name, user, **options)
        transaction do
          group = create!(name: name, active: true)
          group.join!(user, :admin)

          # Allow host app to extend group creation
          yield(group, options) if block_given?

          group
        end
      end
    end
  end
end
