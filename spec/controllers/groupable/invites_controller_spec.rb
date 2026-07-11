require 'rails_helper'

RSpec.describe Groupable::InvitesController, type: :controller do
  routes { Groupable::Engine.routes }

  let(:user) { create(:user) }
  let(:group) { create(:groupable_group) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'POST #create' do
    context 'when user is editor' do
      before do
        create(:groupable_member, :editor, user: user, group: group)
      end

      it 'creates a new invite code' do
        expect {
          post :create, params: { group_id: group.id }
        }.to change { Groupable::Invite.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(json['code']).to be_present
        expect(json['code']).to match(/\A[a-zA-Z0-9]+\z/)
      end

      it 'creates invite associated with the group' do
        post :create, params: { group_id: group.id }

        invite = Groupable::Invite.last
        expect(invite.group).to eq(group)
      end
    end

    context 'when user is admin' do
      before do
        create(:groupable_member, :admin, user: user, group: group)
      end

      it 'creates a new invite code' do
        expect {
          post :create, params: { group_id: group.id }
        }.to change { Groupable::Invite.count }.by(1)

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when user is member' do
      before do
        create(:groupable_member, user: user, group: group)
      end

      it 'returns forbidden' do
        expect {
          post :create, params: { group_id: group.id }
        }.not_to change { Groupable::Invite.count }

        expect(response).to have_http_status(:forbidden)
      end
    end

    context 'when user is not member of the group' do
      let(:other_group) { create(:groupable_group) }

      it 'returns not found' do
        post :create, params: { group_id: other_group.id }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when invites are disabled' do
      before do
        create(:groupable_member, :admin, user: user, group: group)
        Groupable.configuration.enable_invites = false
      end

      after do
        Groupable.configuration.enable_invites = true
      end

      it 'returns not found' do
        expect {
          post :create, params: { group_id: group.id }
        }.not_to change { Groupable::Invite.count }

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
