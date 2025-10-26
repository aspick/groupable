require 'rails_helper'

RSpec.describe Groupable::MemberBehavior, type: :model do
  # Create a custom member class for testing the concern
  before(:all) do
    class CustomMember < ApplicationRecord
      self.table_name = 'groupable_members'
      include Groupable::MemberBehavior
    end
  end

  after(:all) do
    Object.send(:remove_const, :CustomMember)
  end

  let(:group) { create(:groupable_group) }
  let(:user) { create(:user) }

  describe 'associations' do
    let(:custom_member) { CustomMember.create!(group: group, user: user, role: :member) }

    it 'belongs to group' do
      expect(custom_member.group).to eq(group)
    end

    it 'belongs to user' do
      expect(custom_member.user).to eq(user)
    end
  end

  describe 'validations' do
    it 'validates presence of role' do
      member = CustomMember.new(group: group, user: user, role: nil)
      expect(member).not_to be_valid
      expect(member.errors[:role]).to be_present
    end

    it 'validates uniqueness of user_id scoped to group_id' do
      CustomMember.create!(group: group, user: user, role: :member)
      duplicate = CustomMember.new(group: group, user: user, role: :editor)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already been taken')
    end
  end

  describe 'enum role' do
    let(:custom_member) { CustomMember.create!(group: group, user: user, role: :member) }

    it 'supports member role' do
      custom_member.role = :member
      expect(custom_member.member?).to be true
    end

    it 'supports editor role' do
      custom_member.role = :editor
      expect(custom_member.editor?).to be true
    end

    it 'supports admin role' do
      custom_member.role = :admin
      expect(custom_member.admin?).to be true
    end
  end
end
