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
      expect(config.roles).to eq([:member, :editor, :admin])
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
end
