require 'rails_helper'

RSpec.describe Groupable::UserGroupable, type: :model do
  describe 'included in User model' do
    let(:user) { create(:user) }
    let(:group1) { create(:groupable_group) }
    let(:group2) { create(:groupable_group) }

    before do
      create(:groupable_member, user: user, group: group1)
      create(:groupable_member, user: user, group: group2)
    end

    it 'has groupable_members association' do
      expect(user.groupable_members.count).to eq(2)
    end

    it 'has groupable_groups association through members' do
      expect(user.groupable_groups).to contain_exactly(group1, group2)
    end

    it 'provides groups alias method' do
      expect(user.groups).to contain_exactly(group1, group2)
    end

    it 'provides members alias method' do
      expect(user.members.count).to eq(2)
    end

    it 'defines aliases as real associations usable with reflection APIs' do
      expect(
        User.joins(:groups).where(groupable_groups: { id: group1.id })
      ).to include(user)
      expect { User.includes(:members).load }.not_to raise_error
    end

    context 'when user is destroyed' do
      it 'destroys associated members' do
        expect {
          user.destroy
        }.to change { Groupable::Member.count }.by(-2)
      end
    end
  end
end
