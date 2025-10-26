require 'rails_helper'

RSpec.describe 'Groupable Workflow', type: :model do
  let(:creator) { create(:user) }
  let(:invitee) { create(:user) }

  describe 'complete group lifecycle' do
    it 'creates group, generates invite, and allows user to join' do
      # Step 1: Creator creates a new group
      group = Groupable::Group.create_new_group!('Test Group', creator)
      expect(group).to be_persisted
      expect(group.active).to be true

      # Verify creator is admin
      creator_member = group.member_of_user(creator)
      expect(creator_member.role).to eq('admin')

      # Step 2: Creator generates invite code
      invite = group.invites.create!
      expect(invite.code).to be_present

      # Step 3: Check invite is valid
      found_invite = Groupable::Invite.where_active_invite(invite.code).first
      expect(found_invite).to eq(invite)
      expect(found_invite.group).to eq(group)

      # Step 4: Invitee joins the group
      expect(group.joined?(invitee)).to be false
      group.join!(invitee)

      # Verify invitee is now member
      expect(group.joined?(invitee)).to be true
      invitee_member = group.member_of_user(invitee)
      expect(invitee_member.role).to eq('member')

      # Step 5: Invitee can see the group in their list
      expect(invitee.groupable_groups).to include(group)

      # Step 6: Creator promotes invitee to editor
      invitee_member.update!(role: :editor)
      expect(invitee_member.reload.role).to eq('editor')

      # Step 7: Verify group can be updated
      group.update!(name: 'Updated Group Name')
      expect(group.reload.name).to eq('Updated Group Name')

      # Step 8: Admin soft-deletes the group
      group.update!(active: false)
      expect(group.reload.active).to be false
      expect(Groupable::Group.find_by(id: group.id)).to be_nil
      expect(Groupable::Group.unscoped.find(group.id)).to be_present
    end
  end

  describe 'expired invite workflow' do
    it 'prevents joining with expired invite' do
      group = Groupable::Group.create_new_group!('Test Group', creator)
      expired_invite = create(:groupable_invite, :expired, group: group)

      # Expired invite should not be found
      found_invite = Groupable::Invite.where_active_invite(expired_invite.code).first
      expect(found_invite).to be_nil

      # User cannot join without valid invite
      expect(group.joined?(invitee)).to be false
    end
  end

  describe 'permission enforcement workflow' do
    let!(:group) { create(:groupable_group) }
    let!(:admin) { create(:user) }
    let!(:editor) { create(:user) }
    let!(:member) { create(:user) }
    let!(:admin_member) { create(:groupable_member, :admin, user: admin, group: group) }
    let!(:editor_member) { create(:groupable_member, :editor, user: editor, group: group) }
    let!(:regular_member) { create(:groupable_member, user: member, group: group) }

    it 'enforces role-based permissions correctly' do
      # Admin can perform all actions
      expect(admin_member.admin?).to be true

      # Editor has elevated permissions
      expect(editor_member.editor?).to be true

      # Regular member has basic permissions
      expect(regular_member.member?).to be true

      # Test role hierarchy
      expect(admin_member.admin?).to be true
      expect(admin_member.editor?).to be false
      expect(admin_member.member?).to be false

      # Editor members include both editor and admin roles
      expect(group.editor_members).to include(admin_member, editor_member)
      expect(group.editor_members).not_to include(regular_member)

      # Soft delete works
      group.update!(active: false)
      expect(group.reload.active).to be false
    end
  end

  describe 'multiple groups per user workflow' do
    it 'allows user to be member of multiple groups with different roles' do
      user = create(:user)

      # Create first group (user becomes admin)
      group1 = Groupable::Group.create_new_group!('Group 1', user)

      # Create second group (user becomes admin)
      group2 = Groupable::Group.create_new_group!('Group 2', user)

      # User should see both groups
      expect(user.groupable_groups).to contain_exactly(group1, group2)

      # Verify user is admin in both groups
      expect(group1.member_of_user(user).role).to eq('admin')
      expect(group2.member_of_user(user).role).to eq('admin')

      # User should have access to both groups' members
      expect(group1.members.count).to eq(1)
      expect(group2.members.count).to eq(1)
    end
  end
end
