require 'rails_helper'

RSpec.describe Groupable::Configuration do
  # Reset configuration before each test in this file only
  before(:each) do
    Groupable.reset_configuration!
  end
  describe 'default configuration' do
    let(:config) { Groupable::Configuration.new }

    it 'has default user_class_name' do
      expect(config.user_class_name).to eq('User')
    end

    it 'has default group_class_name' do
      expect(config.group_class_name).to eq('Groupable::Group')
    end

    it 'has default member_class_name' do
      expect(config.member_class_name).to eq('Groupable::Member')
    end

    it 'has default invite_class_name' do
      expect(config.invite_class_name).to eq('Groupable::Invite')
    end

    it 'has default enable_invites' do
      expect(config.enable_invites).to be true
    end

    it 'has default invite_expiry_days' do
      expect(config.invite_expiry_days).to eq(30)
    end

    it 'has default default_role' do
      expect(config.default_role).to eq(:member)
    end

    it 'has default roles' do
      expect(config.roles).to eq([ :member, :editor, :admin ])
    end
  end

  describe 'class name getters' do
    let(:config) { Groupable::Configuration.new }

    it 'returns configured group_class_name' do
      config.group_class_name = 'CustomGroup'
      expect(config.group_class_name).to eq('CustomGroup')
    end

    it 'returns configured member_class_name' do
      config.member_class_name = 'CustomMember'
      expect(config.member_class_name).to eq('CustomMember')
    end

    it 'returns configured invite_class_name' do
      config.invite_class_name = 'CustomInvite'
      expect(config.invite_class_name).to eq('CustomInvite')
    end
  end

  describe 'class getters' do
    let(:config) { Groupable::Configuration.new }

    it 'returns user class' do
      expect(config.user_class).to eq(User)
    end

    it 'returns group class' do
      expect(config.group_class).to eq(Groupable::Group)
    end

    it 'returns member class' do
      expect(config.member_class).to eq(Groupable::Member)
    end

    it 'returns invite class' do
      expect(config.invite_class).to eq(Groupable::Invite)
    end
  end

  describe 'table name getters' do
    let(:config) { Groupable::Configuration.new }

    it 'returns group table name' do
      expect(config.group_table_name).to eq('groupable_groups')
    end

    it 'returns member table name' do
      expect(config.member_table_name).to eq('groupable_members')
    end

    it 'returns invite table name' do
      expect(config.invite_table_name).to eq('groupable_invites')
    end
  end

  describe 'Groupable.configuration' do
    it 'returns configuration instance' do
      expect(Groupable.configuration).to be_a(Groupable::Configuration)
    end

    it 'returns same instance on multiple calls' do
      config1 = Groupable.configuration
      config2 = Groupable.configuration
      expect(config1).to be(config2)
    end
  end

  describe 'Groupable.configure' do
    it 'yields configuration instance' do
      expect { |b|
        Groupable.configure(&b)
      }.to yield_with_args(Groupable::Configuration)
    end

    it 'allows setting configuration values' do
      Groupable.configure do |config|
        config.invite_expiry_days = 7
        config.default_role = :editor
      end

      expect(Groupable.configuration.invite_expiry_days).to eq(7)
      expect(Groupable.configuration.default_role).to eq(:editor)
    end
  end

  describe 'Groupable.reset_configuration!' do
    it 'resets configuration to defaults' do
      Groupable.configure do |config|
        config.invite_expiry_days = 7
        config.default_role = :editor
      end

      Groupable.reset_configuration!

      expect(Groupable.configuration.invite_expiry_days).to eq(30)
      expect(Groupable.configuration.default_role).to eq(:member)
    end
  end

  describe 'custom table names' do
    let(:config) { Groupable::Configuration.new }

    it 'has default nil values for custom table names' do
      expect(config.groups_table_name).to be_nil
      expect(config.members_table_name).to be_nil
      expect(config.users_table_name).to be_nil
    end

    it 'allows setting custom table names' do
      config.groups_table_name = 'custom_groups'
      config.members_table_name = 'custom_members'
      config.users_table_name = 'custom_users'

      expect(config.groups_table_name).to eq('custom_groups')
      expect(config.members_table_name).to eq('custom_members')
      expect(config.users_table_name).to eq('custom_users')
    end

    it 'returns custom table name when set' do
      config.groups_table_name = 'my_groups'
      expect(config.group_table_name).to eq('my_groups')
    end

    it 'falls back to class table_name when custom table name is nil' do
      config.groups_table_name = nil
      expect(config.group_table_name).to eq('groupable_groups')
    end
  end

  describe 'custom association names' do
    let(:config) { Groupable::Configuration.new }

    it 'has default association names' do
      expect(config.members_association_name).to eq(:groupable_members)
      expect(config.groups_association_name).to eq(:groupable_groups)
    end

    it 'allows setting custom association names' do
      config.members_association_name = :team_members
      config.groups_association_name = :teams

      expect(config.members_association_name).to eq(:team_members)
      expect(config.groups_association_name).to eq(:teams)
    end

    it 'allows setting nil to use defaults' do
      config.members_association_name = nil
      config.groups_association_name = nil

      expect(config.members_association_name).to be_nil
      expect(config.groups_association_name).to be_nil
    end
  end

  describe '#validate!' do
    let(:config) { Groupable::Configuration.new }

    context 'with valid configuration' do
      it 'returns true' do
        expect(config.validate!).to be true
      end
    end

    context 'with string roles (YAML config scenario)' do
      it 'does not raise error when roles are strings instead of symbols' do
        config.roles = [ 'member', 'editor', 'admin' ]
        expect { config.validate! }.not_to raise_error
      end
    end

    context 'with invalid class name' do
      it 'raises ConfigurationError for non-existent user class' do
        config.user_class_name = 'NonExistentUser'
        expect { config.validate! }.to raise_error(
          Groupable::ConfigurationError,
          /User class 'NonExistentUser' not found/
        )
      end

      it 'raises ConfigurationError for non-existent group class' do
        config.group_class_name = 'NonExistentGroup'
        expect { config.validate! }.to raise_error(
          Groupable::ConfigurationError,
          /Group class 'NonExistentGroup' not found/
        )
      end

      it 'raises ConfigurationError for non-existent member class' do
        config.member_class_name = 'NonExistentMember'
        expect { config.validate! }.to raise_error(
          Groupable::ConfigurationError,
          /Member class 'NonExistentMember' not found/
        )
      end
    end

    context 'with missing role enum' do
      before do
        # Create a temporary class without role enum
        stub_const('MemberWithoutRole', Class.new do
          def self.name
            'MemberWithoutRole'
          end
        end)
        config.member_class_name = 'MemberWithoutRole'
      end

      it 'raises ConfigurationError with helpful message' do
        expect { config.validate! }.to raise_error(
          Groupable::ConfigurationError,
          /Member model 'MemberWithoutRole' must have a 'role' enum/
        )
      end
    end

    context 'with missing roles in enum' do
      before do
        # Create a temporary class with incomplete role enum
        stub_const('MemberWithIncompleteRoles', Class.new do
          def self.name
            'MemberWithIncompleteRoles'
          end

          def self.roles
            { 'member' => 1 }
          end

          def self.respond_to?(method)
            method == :roles || super
          end
        end)
        config.member_class_name = 'MemberWithIncompleteRoles'
      end

      it 'raises ConfigurationError listing missing roles' do
        expect { config.validate! }.to raise_error(
          Groupable::ConfigurationError,
          /missing required roles: editor, admin/
        )
      end
    end
  end
end
