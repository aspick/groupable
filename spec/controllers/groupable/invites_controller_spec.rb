require 'rails_helper'

RSpec.describe Groupable::InvitesController, type: :controller do
  routes { Groupable::Engine.routes }

  let(:user) { create(:user) }
  let(:group) { create(:groupable_group) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    create(:groupable_member, user: user, group: group)
  end

  describe 'POST #create' do
    it 'creates a new invite code' do
      expect {
        post :create, params: { id: group.id }
      }.to change { Groupable::Invite.count }.by(1)

      expect(response).to have_http_status(:ok)
      expect(json['code']).to be_present
      expect(json['code']).to match(/\A[a-zA-Z0-9]+\z/)
    end

    it 'creates invite associated with the group' do
      post :create, params: { id: group.id }

      invite = Groupable::Invite.last
      expect(invite.group).to eq(group)
    end

    context 'when user is not member of the group' do
      let(:other_group) { create(:groupable_group) }

      it 'returns not found' do
        post :create, params: { id: other_group.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
