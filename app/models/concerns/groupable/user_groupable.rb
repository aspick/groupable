module Groupable
  module UserGroupable
    extend ActiveSupport::Concern

    included do
      member_class_name = Groupable.configuration.member_class_name
      group_class_name = Groupable.configuration.group_class_name

      has_many :groupable_members,
               class_name: member_class_name,
               foreign_key: "user_id",
               dependent: :destroy

      has_many :groupable_groups,
               through: :groupable_members,
               source: :group,
               class_name: group_class_name

      # Aliases are defined as real associations (not alias_method) so that
      # reflection-based APIs (joins/includes/preload, serializers) work with
      # them. dependent: :destroy stays only on the canonical association.
      members_assoc_name = Groupable.configuration.members_association_name
      groups_assoc_name = Groupable.configuration.groups_association_name

      members_alias_names = []
      if members_assoc_name && members_assoc_name != :groupable_members
        members_alias_names << members_assoc_name
      end
      members_alias_names << :members unless members_assoc_name == :members

      members_alias_names.each do |alias_name|
        next if method_defined?(alias_name)

        has_many alias_name,
                 class_name: member_class_name,
                 foreign_key: "user_id"
      end

      groups_alias_names = []
      if groups_assoc_name && groups_assoc_name != :groupable_groups
        groups_alias_names << groups_assoc_name
      end
      groups_alias_names << :groups unless groups_assoc_name == :groups

      groups_alias_names.each do |alias_name|
        next if method_defined?(alias_name)

        has_many alias_name,
                 through: :groupable_members,
                 source: :group,
                 class_name: group_class_name
      end
    end
  end
end
