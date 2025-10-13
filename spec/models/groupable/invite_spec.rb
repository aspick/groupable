require 'rails_helper'

RSpec.describe Groupable::Invite, type: :model do
  describe 'associations' do
    it { expect(subject).to respond_to(:group) }
  end

  describe 'code generation' do
    it 'generates code automatically on initialization' do
      invite = Groupable::Invite.new
      expect(invite.code).to be_present
      expect(invite.code).to match(/\A[a-zA-Z0-9]+\z/)
    end

    it 'does not override existing code' do
      invite = Groupable::Invite.new(code: 'custom_code')
      expect(invite.code).to eq('custom_code')
    end

    it 'generates unique codes' do
      invite1 = create(:groupable_invite)
      invite2 = create(:groupable_invite)

      expect(invite1.code).not_to eq(invite2.code)
    end
  end

  describe '.where_active_invite' do
    let(:group) { create(:groupable_group) }
    let!(:active_invite) { create(:groupable_invite, group: group) }
    let!(:expired_invite) { create(:groupable_invite, :expired, group: group) }

    it 'returns active invites within expiry period' do
      result = Groupable::Invite.where_active_invite(active_invite.code)
      expect(result).to include(active_invite)
    end

    it 'does not return expired invites' do
      result = Groupable::Invite.where_active_invite(expired_invite.code)
      expect(result).to be_empty
    end

    it 'returns empty when code does not match' do
      result = Groupable::Invite.where_active_invite('non_existent_code')
      expect(result).to be_empty
    end
  end

  describe '#expired_at' do
    let(:invite) { create(:groupable_invite) }

    it 'returns expiration datetime' do
      expected_expiry = invite.created_at + Groupable.configuration.invite_expiry_days.days
      expect(invite.expired_at).to be_within(1.second).of(expected_expiry)
    end

    context 'with custom expiry days configuration' do
      before do
        Groupable.configure do |config|
          config.invite_expiry_days = 7
        end
      end

      it 'uses configured expiry days' do
        invite = create(:groupable_invite)
        expected_expiry = invite.created_at + 7.days
        expect(invite.expired_at).to be_within(1.second).of(expected_expiry)
      end
    end
  end

  describe 'factory traits' do
    it 'creates active invite by default' do
      invite = create(:groupable_invite)
      result = Groupable::Invite.where_active_invite(invite.code)
      expect(result).to include(invite)
    end

    it 'creates expired invite with trait' do
      invite = create(:groupable_invite, :expired)
      expect(invite.created_at).to be < 31.days.ago
      result = Groupable::Invite.where_active_invite(invite.code)
      expect(result).to be_empty
    end
  end
end
