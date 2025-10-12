module Groupable
  class Configuration
    attr_accessor :user_class_name,
                  :enable_invites,
                  :invite_expiry_days,
                  :default_role,
                  :roles

    attr_writer :group_class_name,
                :member_class_name,
                :invite_class_name

    def initialize
      @user_class_name = 'User'
      @group_class_name = 'Groupable::Group'
      @member_class_name = 'Groupable::Member'
      @invite_class_name = 'Groupable::Invite'
      @enable_invites = true
      @invite_expiry_days = 30
      @default_role = :member
      @roles = [:member, :editor, :admin]
    end

    # Class name getters
    def group_class_name
      @group_class_name
    end

    def member_class_name
      @member_class_name
    end

    def invite_class_name
      @invite_class_name
    end

    # Class getters
    def user_class
      @user_class_name.constantize
    end

    def group_class
      @group_class_name.constantize
    end

    def member_class
      @member_class_name.constantize
    end

    def invite_class
      @invite_class_name.constantize
    end

    # Table name getters - automatically derived from class
    def group_table_name
      group_class.table_name
    end

    def member_table_name
      member_class.table_name
    end

    def invite_table_name
      invite_class.table_name
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def reset_configuration!
      @configuration = Configuration.new
    end
  end
end
