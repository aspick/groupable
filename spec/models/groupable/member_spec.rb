require 'rails_helper'

RSpec.describe Groupable::Member, type: :model do
  describe 'associations' do
    it { expect(subject).to respond_to(:group) }
    it { expect(subject).to respond_to(:user) }
  end

  describe 'validations' do
    let(:group) { create(:groupable_group) }
    let(:user) { create(:user) }

    it 'requires role' do
      member = build(:groupable_member, role: nil)
      expect(member).not_to be_valid
      expect(member.errors[:role]).to include("can't be blank")
    end

    it 'validates uniqueness of user_id scoped to group_id' do
      create(:groupable_member, group: group, user: user)
      duplicate_member = build(:groupable_member, group: group, user: user)

      expect(duplicate_member).not_to be_valid
      expect(duplicate_member.errors[:user_id]).to include('has already been taken')
    end

    it 'allows same user in different groups' do
      group1 = create(:groupable_group)
      group2 = create(:groupable_group)

      member1 = create(:groupable_member, group: group1, user: user)
      member2 = build(:groupable_member, group: group2, user: user)

      expect(member2).to be_valid
    end
  end

  describe 'enum role' do
    let(:member) { create(:groupable_member) }

    it 'has member role' do
      member.role = :member
      expect(member.member?).to be true
      expect(member.role).to eq('member')
    end

    it 'has editor role' do
      member.role = :editor
      expect(member.editor?).to be true
      expect(member.role).to eq('editor')
    end

    it 'has admin role' do
      member.role = :admin
      expect(member.admin?).to be true
      expect(member.role).to eq('admin')
    end

    it 'can query by role' do
      create(:groupable_member, role: :member)
      create(:groupable_member, :editor)
      create(:groupable_member, :admin)

      expect(Groupable::Member.member.count).to eq(1)
      expect(Groupable::Member.editor.count).to eq(1)
      expect(Groupable::Member.admin.count).to eq(1)
    end
  end

  describe 'factory traits' do
    it 'creates member with member role' do
      member = create(:groupable_member)
      expect(member.role).to eq('member')
    end

    it 'creates member with editor role using trait' do
      member = create(:groupable_member, :editor)
      expect(member.role).to eq('editor')
    end

    it 'creates member with admin role using trait' do
      member = create(:groupable_member, :admin)
      expect(member.role).to eq('admin')
    end
  end
end
