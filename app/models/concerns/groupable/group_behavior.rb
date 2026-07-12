module Groupable
  module GroupBehavior
    extend ActiveSupport::Concern

    included do
      # Configuration values are read when this concern is included.
      # Groupable must be configured (typically in an initializer) before
      # the including model class is loaded.
      member_class_name = Groupable.configuration.member_class_name
      user_class_name = Groupable.configuration.user_class_name
      invite_class_name = Groupable.configuration.invite_class_name

      has_many :groupable_members,
               -> { extending GroupableMembersExtension },
               class_name: member_class_name,
               foreign_key: :group_id,
               dependent: :destroy

      has_many :groupable_users,
               through: :groupable_members,
               source: :user,
               class_name: user_class_name

      if Groupable.configuration.enable_invites
        has_many :groupable_invites,
                 class_name: invite_class_name,
                 foreign_key: :group_id,
                 dependent: :destroy
      end

      scope :active, -> { where(active: true) } unless respond_to?(:active)

      # Aliases are defined as real associations (not alias_method) so that
      # reflection-based APIs (joins/includes/preload, serializers) work with
      # them. dependent: :destroy stays only on the canonical associations.
      members_alias_names = []
      members_assoc_name = Groupable.configuration.members_association_name
      if members_assoc_name && members_assoc_name != :groupable_members
        members_alias_names << members_assoc_name
      end
      members_alias_names << :members unless members_assoc_name == :members

      members_alias_names.each do |alias_name|
        next if method_defined?(alias_name)

        has_many alias_name,
                 -> { extending GroupableMembersExtension },
                 class_name: member_class_name,
                 foreign_key: :group_id
      end

      unless method_defined?(:users)
        has_many :users,
                 through: :groupable_members,
                 source: :user,
                 class_name: user_class_name
      end

      if Groupable.configuration.enable_invites && !method_defined?(:invites)
        has_many :invites,
                 class_name: invite_class_name,
                 foreign_key: :group_id
      end
    end

    module GroupableMembersExtension
      # Extension methods for groupable_members association
    end

    # Check if user has joined this group
    # @param [Object] user - User object
    # @return [Boolean] joined
    def joined?(user)
      groupable_members.exists?(user_id: user.id)
    end

    # Add user to this group
    # @param [Object] user - User object
    # @param [Symbol] role - Role for the user (:member, :editor, :admin)
    # @return [Member] created member
    def join!(user, role = nil)
      role ||= Groupable.configuration.default_role
      raise ArgumentError, "user does not exist" unless user
      raise ArgumentError, "user is already joined" if joined?(user)

      groupable_members.create!(user: user, role: role)
    end

    # Get member record for user
    # @param [Object] user - User object
    # @return [Member, nil] member
    def member_of_user(user)
      groupable_members.find_by(user_id: user.id)
    end

    # Get editor and admin members
    # @return [ActiveRecord::Relation] members with editor or admin role
    def editor_members
      groupable_members.where(role: [ :editor, :admin ])
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
