require 'rails_helper'

RSpec.describe 'Custom Association Names', type: :model do
  # Clean up after each test
  after(:each) do
    Groupable.reset_configuration!
    
    # Remove dynamically created classes
    Object.send(:remove_const, :CustomGroup) if defined?(CustomGroup)
    Object.send(:remove_const, :CustomUser) if defined?(CustomUser)
  end

  describe 'with custom members_association_name' do
    before do
      Groupable.configure do |config|
        config.members_association_name = :team_members
      end

      # Create a test class that includes the concern
      class CustomGroup < ApplicationRecord
        self.table_name = 'groupable_groups'
        include Groupable::GroupBehavior
      end
    end

    it 'creates custom association name alias' do
      group = CustomGroup.new
      expect(group).to respond_to(:team_members)
    end

    it 'still provides groupable_members association' do
      group = CustomGroup.new
      expect(group).to respond_to(:groupable_members)
    end

    it 'custom alias points to same association' do
      group = create(:groupable_group)
      user = create(:user)
      
      # Use the base class to create a member
      Groupable::Group.find(group.id).join!(user, :member)
      
      # Custom class should see the same member through custom alias
      custom_group = CustomGroup.find(group.id)
      expect(custom_group.team_members.count).to eq(1)
      expect(custom_group.groupable_members.count).to eq(1)
    end
  end

  describe 'with nil association names (using defaults)' do
    before do
      Groupable.configure do |config|
        config.members_association_name = nil
        config.groups_association_name = nil
      end

      class CustomUser < ApplicationRecord
        self.table_name = 'users'
        include Groupable::UserGroupable
      end
    end

    it 'does not raise TypeError' do
      expect { CustomUser.new }.not_to raise_error
    end

    it 'still provides default aliases' do
      user = CustomUser.new
      expect(user).to respond_to(:members)
      expect(user).to respond_to(:groups)
    end
  end

  describe 'backward compatibility' do
    before do
      # Use default configuration
      class CustomGroup < ApplicationRecord
        self.table_name = 'groupable_groups'
        include Groupable::GroupBehavior
      end
    end

    it 'provides :members alias by default' do
      group = CustomGroup.new
      expect(group).to respond_to(:members)
    end

    it 'provides :users alias by default' do
      group = CustomGroup.new
      expect(group).to respond_to(:users)
    end
  end
end
