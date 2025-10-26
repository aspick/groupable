require 'rails_helper'

RSpec.describe Groupable::GroupBehavior, type: :model do
  # Create a custom group class for testing the concern
  before(:all) do
    class CustomGroup < ApplicationRecord
      self.table_name = 'groupable_groups'
      include Groupable::GroupBehavior
    end
  end

  after(:all) do
    Object.send(:remove_const, :CustomGroup)
  end

  let(:custom_group) { CustomGroup.create!(name: 'Custom Group', active: true) }
  let(:user) { create(:user) }

  describe 'associations' do
    it 'has groupable_members association' do
      expect(custom_group).to respond_to(:groupable_members)
    end

    it 'has groupable_users association' do
      expect(custom_group).to respond_to(:groupable_users)
    end

    it 'provides members alias' do
      expect(custom_group).to respond_to(:members)
    end

    it 'provides users alias' do
      expect(custom_group).to respond_to(:users)
    end
  end

  describe '#joined?' do
    context 'when user is a member' do
      before { custom_group.join!(user) }

      it 'returns true' do
        expect(custom_group.joined?(user)).to be true
      end
    end

    context 'when user is not a member' do
      it 'returns false' do
        expect(custom_group.joined?(user)).to be false
      end
    end
  end

  describe '#join!' do
    it 'adds user to the group with default role' do
      expect {
        custom_group.join!(user)
      }.to change { custom_group.members.count }.by(1)

      member = custom_group.members.last
      expect(member.user).to eq(user)
      expect(member.role).to eq('member')
    end

    it 'adds user with specified role' do
      custom_group.join!(user, :admin)
      member = custom_group.members.last
      expect(member.role).to eq('admin')
    end

    it 'raises error when user is nil' do
      expect {
        custom_group.join!(nil)
      }.to raise_error(ArgumentError, 'user does not exist')
    end

    it 'raises error when user already joined' do
      custom_group.join!(user)
      expect {
        custom_group.join!(user)
      }.to raise_error(ArgumentError, 'user is already joined')
    end
  end

  describe '#member_of_user' do
    before { custom_group.join!(user, :editor) }

    it 'returns member record for the user' do
      member = custom_group.member_of_user(user)
      expect(member).to be_present
      expect(member.user).to eq(user)
    end

    it 'returns nil for non-member' do
      other_user = create(:user)
      expect(custom_group.member_of_user(other_user)).to be_nil
    end
  end

  describe '#editor_members' do
    let(:member_user) { create(:user) }
    let(:editor_user) { create(:user) }
    let(:admin_user) { create(:user) }

    before do
      Groupable::Member.create!(group_id: custom_group.id, user: member_user, role: :member)
      Groupable::Member.create!(group_id: custom_group.id, user: editor_user, role: :editor)
      Groupable::Member.create!(group_id: custom_group.id, user: admin_user, role: :admin)
    end

    it 'returns only editor and admin members' do
      editors = custom_group.editor_members
      expect(editors.count).to eq(2)
      expect(editors.map(&:user)).to contain_exactly(editor_user, admin_user)
    end
  end

  describe '.create_new_group!' do
    it 'creates group with user as admin' do
      group = CustomGroup.create_new_group!('New Group', user)

      expect(group.name).to eq('New Group')
      expect(group.active).to be true
      expect(group.members.count).to eq(1)
      expect(group.members.first.user).to eq(user)
      expect(group.members.first.role).to eq('admin')
    end

    it 'executes block when given' do
      block_executed = false
      group = CustomGroup.create_new_group!('New Group', user) do |g, options|
        block_executed = true
      end

      expect(block_executed).to be true
    end
  end
end
