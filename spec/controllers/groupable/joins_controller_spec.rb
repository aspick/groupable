require 'rails_helper'

RSpec.describe Groupable::JoinsController, type: :controller do
  routes { Groupable::Engine.routes }

  let(:user) { create(:user) }
  let(:group) { create(:groupable_group) }
  let(:invite) { create(:groupable_invite, group: group) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #show' do
    context 'with valid invite code' do
      it 'returns the group information' do
        get :show, params: { code: invite.code }

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(group.id)
        expect(json['name']).to eq(group.name)
      end
    end

    context 'with expired invite code' do
      let(:expired_invite) { create(:groupable_invite, :expired, group: group) }

      it 'returns not found' do
        get :show, params: { code: expired_invite.code }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid invite code' do
      it 'returns not found' do
        get :show, params: { code: 'invalid_code' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    context 'with valid invite code' do
      it 'adds user to the group' do
        expect {
          post :create, params: { code: invite.code }
        }.to change { group.members.count }.by(1)

        expect(response).to have_http_status(:ok)
        expect(json['status']).to eq('ok')
        expect(group.joined?(user)).to be true
      end

      it 'adds user with default role' do
        post :create, params: { code: invite.code }

        member = group.members.find_by(user: user)
        expect(member.role).to eq('member')
      end
    end

    context 'when user already joined' do
      before do
        group.join!(user)
      end

      it 'returns no content without error' do
        expect {
          post :create, params: { code: invite.code }
        }.not_to change { group.members.count }

        expect(response).to have_http_status(:no_content)
      end
    end

    context 'with expired invite code' do
      let(:expired_invite) { create(:groupable_invite, :expired, group: group) }

      it 'returns not found' do
        post :create, params: { code: expired_invite.code }
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with invalid invite code' do
      it 'returns not found' do
        post :create, params: { code: 'invalid_code' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
