module Groupable
  module UserGroupable
    extend ActiveSupport::Concern

    included do
      member_class_name = Groupable.configuration.member_class_name
      group_class_name = Groupable.configuration.group_class_name

      has_many :groupable_members,
               class_name: member_class_name,
               foreign_key: 'user_id',
               dependent: :destroy

      has_many :groupable_groups,
               through: :groupable_members,
               source: :group,
               class_name: group_class_name

      # Create custom association name aliases if configured
      members_assoc_name = Groupable.configuration.members_association_name
      groups_assoc_name = Groupable.configuration.groups_association_name

      if members_assoc_name != :groupable_members && !method_defined?(members_assoc_name)
        alias_method members_assoc_name, :groupable_members
      end

      if groups_assoc_name != :groupable_groups && !method_defined?(groups_assoc_name)
        alias_method groups_assoc_name, :groupable_groups
      end

      # Backward compatibility: provide simpler aliases if not already defined
      # and not conflicting with custom association names
      if members_assoc_name != :members && !method_defined?(:members)
        alias_method :members, :groupable_members
      end

      if groups_assoc_name != :groups && !method_defined?(:groups)
        alias_method :groups, :groupable_groups
      end
    end
  end
end
