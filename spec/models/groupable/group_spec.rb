require 'rails_helper'

RSpec.describe Groupable::Group, type: :model do
  describe 'associations' do
    it { expect(subject).to respond_to(:members) }
    it { expect(subject).to respond_to(:users) }
    it { expect(subject).to respond_to(:invites) }
  end

  describe 'default scope' do
    let!(:active_group) { create(:groupable_group, active: true) }
    let!(:inactive_group) { create(:groupable_group, :inactive) }

    it 'returns only active groups' do
      expect(Groupable::Group.all).to include(active_group)
      expect(Groupable::Group.all).not_to include(inactive_group)
    end

    it 'can access inactive groups with unscoped' do
      expect(Groupable::Group.unscoped.all).to include(active_group)
      expect(Groupable::Group.unscoped.all).to include(inactive_group)
    end
  end

  describe '#joined?' do
    let(:group) { create(:groupable_group) }
    let(:user) { create(:user) }
    let(:member_user) { create(:user) }

    before do
      create(:groupable_member, group: group, user: member_user)
    end

    it 'returns true if user has joined the group' do
      expect(group.joined?(member_user)).to be true
    end

    it 'returns false if user has not joined the group' do
      expect(group.joined?(user)).to be false
    end
  end

  describe '#join!' do
    let(:group) { create(:groupable_group) }
    let(:user) { create(:user) }

    context 'when user is valid and not joined' do
      it 'creates a new member with default role' do
        expect {
          group.join!(user)
        }.to change { group.members.count }.by(1)

        member = group.members.last
        expect(member.user).to eq(user)
        expect(member.role).to eq('member')
      end

      it 'creates a new member with specified role' do
        group.join!(user, :editor)
        member = group.members.last
        expect(member.role).to eq('editor')
      end
    end

    context 'when user is nil' do
      it 'raises ArgumentError' do
        expect {
          group.join!(nil)
        }.to raise_error(ArgumentError, 'user is not exist')
      end
    end

    context 'when user has already joined' do
      before { group.join!(user) }

      it 'raises ArgumentError' do
        expect {
          group.join!(user)
        }.to raise_error(ArgumentError, 'user is already joined')
      end
    end
  end

  describe '#member_of_user' do
    let(:group) { create(:groupable_group) }
    let(:user) { create(:user) }
    let(:non_member_user) { create(:user) }

    before do
      create(:groupable_member, group: group, user: user, role: :editor)
    end

    it 'returns member record for the user' do
      member = group.member_of_user(user)
      expect(member).to be_present
      expect(member.user).to eq(user)
      expect(member.role).to eq('editor')
    end

    it 'returns nil for non-member user' do
      expect(group.member_of_user(non_member_user)).to be_nil
    end
  end

  describe '#editor_members' do
    let(:group) { create(:groupable_group) }
    let(:member_user) { create(:user) }
    let(:editor_user) { create(:user) }
    let(:admin_user) { create(:user) }

    before do
      create(:groupable_member, group: group, user: member_user, role: :member)
      create(:groupable_member, group: group, user: editor_user, role: :editor)
      create(:groupable_member, group: group, user: admin_user, role: :admin)
    end

    it 'returns only editor and admin members' do
      editor_members = group.editor_members
      expect(editor_members.count).to eq(2)
      expect(editor_members.map(&:user)).to contain_exactly(editor_user, admin_user)
    end
  end

  describe '.create_new_group!' do
    let(:user) { create(:user) }

    it 'creates a new group with the user as admin' do
      expect {
        @group = Groupable::Group.create_new_group!('Test Group', user)
      }.to change { Groupable::Group.count }.by(1)
        .and change { Groupable::Member.count }.by(1)

      expect(@group.name).to eq('Test Group')
      expect(@group.active).to be true
      expect(@group.members.count).to eq(1)

      member = @group.members.first
      expect(member.user).to eq(user)
      expect(member.role).to eq('admin')
    end

    it 'executes block if given' do
      block_executed = false
      group = Groupable::Group.create_new_group!('Test Group', user) do |g, options|
        block_executed = true
        expect(g).to be_a(Groupable::Group)
      end

      expect(block_executed).to be true
    end

    it 'rolls back on error' do
      allow_any_instance_of(Groupable::Group).to receive(:join!).and_raise(StandardError)

      expect {
        Groupable::Group.create_new_group!('Test Group', user)
      }.to raise_error(StandardError)
        .and change { Groupable::Group.unscoped.count }.by(0)
        .and change { Groupable::Member.count }.by(0)
    end
  end

  describe 'has_secure_password' do
    let(:group) { create(:groupable_group) }

    it 'allows setting and authenticating password' do
      group.password = 'test_password'
      group.save

      expect(group.authenticate('test_password')).to eq(group)
      expect(group.authenticate('wrong_password')).to be false
    end
  end
end
