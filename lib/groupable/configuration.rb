module Groupable
  class Configuration
    attr_accessor :user_class_name,
                  :parent_controller,
                  :current_user_resolver,
                  :group_class_name,
                  :member_class_name,
                  :invite_class_name,
                  :enable_invites,
                  :invite_expiry_days,
                  :default_role,
                  :roles,
                  :members_association_name,
                  :groups_association_name

    def initialize
      @user_class_name = "User"
      @parent_controller = "ActionController::API"
      @current_user_resolver = nil
      @group_class_name = "Groupable::Group"
      @member_class_name = "Groupable::Member"
      @invite_class_name = "Groupable::Invite"
      @enable_invites = true
      @invite_expiry_days = 30
      @default_role = :member
      @roles = [ :member, :editor, :admin ]
      @members_association_name = :groupable_members
      @groups_association_name = :groupable_groups
    end

    def parent_controller_class
      @parent_controller.constantize
    end

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

    # Validate configuration and provide helpful error messages
    # This method can be called after configuration to ensure everything is set up correctly
    def validate!
      validate_class_exists!
      validate_member_class_structure!
      true
    end

    private

    def validate_class_exists!
      # Validate that all configured classes exist and can be constantized
      begin
        user_class
      rescue NameError
        raise Groupable::ConfigurationError,
              "User class '#{@user_class_name}' not found. Please ensure the class exists and is loaded."
      end

      begin
        group_class
      rescue NameError
        raise Groupable::ConfigurationError,
              "Group class '#{@group_class_name}' not found. Please ensure the class exists and is loaded."
      end

      begin
        member_class
      rescue NameError
        raise Groupable::ConfigurationError,
              "Member class '#{@member_class_name}' not found. Please ensure the class exists and is loaded."
      end

      if @enable_invites
        begin
          invite_class
        rescue NameError
          raise Groupable::ConfigurationError,
                "Invite class '#{@invite_class_name}' not found. Please ensure the class exists and is loaded, or disable invites with 'config.enable_invites = false'."
        end
      end
    end

    def validate_member_class_structure!
      # Validate that member class has required role enum
      klass = member_class
      unless klass.respond_to?(:roles)
        raise Groupable::ConfigurationError,
              "Member model '#{@member_class_name}' must have a 'role' enum. " \
              "Expected roles: #{@roles.join(', ')}. " \
              "Add 'enum :role, { member: 1, editor: 2, admin: 3 }' to your Member model."
      end

      # Validate that configured roles exist in the enum
      # Normalize both to symbols for comparison
      configured_roles = @roles.map(&:to_sym)
      enum_roles = klass.roles.keys.map(&:to_sym)
      missing_roles = configured_roles - enum_roles

      if missing_roles.any?
        raise Groupable::ConfigurationError,
              "Member model '#{@member_class_name}' is missing required roles: #{missing_roles.join(', ')}. " \
              "Current roles: #{klass.roles.keys.join(', ')}. " \
              "Expected roles: #{@roles.join(', ')}."
      end
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
