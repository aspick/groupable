require 'rails_helper'

RSpec.describe Groupable::GroupsController, type: :controller do
  routes { Groupable::Engine.routes }

  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:group1) { create(:groupable_group) }
    let!(:group2) { create(:groupable_group) }
    let!(:other_group) { create(:groupable_group) }

    before do
      create(:groupable_member, user: user, group: group1)
      create(:groupable_member, user: user, group: group2)
      create(:groupable_member, user: other_user, group: other_group)
    end

    it 'returns groups that user belongs to' do
      get :index

      expect(response).to have_http_status(:ok)
      groups = json
      expect(groups.count).to eq(2)
      expect(groups.map { |g| g['id'] }).to contain_exactly(group1.id, group2.id)
    end
  end

  describe 'GET #show' do
    let(:group) { create(:groupable_group) }

    before do
      create(:groupable_member, user: user, group: group)
    end

    context 'when user is member of the group' do
      it 'returns the group' do
        get :show, params: { id: group.id }

        expect(response).to have_http_status(:ok)
        expect(json['id']).to eq(group.id)
        expect(json['name']).to eq(group.name)
      end
    end

    context 'when user is not member of the group' do
      let(:other_group) { create(:groupable_group) }

      it 'returns not found' do
        get :show, params: { id: other_group.id }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:group_params) do
      { item: { name: 'New Group' } }
    end

    it 'creates a new group with user as admin' do
      expect {
        post :create, params: group_params
      }.to change { Groupable::Group.count }.by(1)
        .and change { Groupable::Member.count }.by(1)

      expect(response).to have_http_status(:created)

      group = Groupable::Group.last
      expect(group.name).to eq('New Group')
      expect(group.members.count).to eq(1)
      expect(group.members.first.user).to eq(user)
      expect(group.members.first.role).to eq('admin')
    end
  end

  describe 'PUT #update' do
    let(:group) { create(:groupable_group, name: 'Old Name') }
    let(:update_params) do
      { item: { name: 'New Name' } }
    end

    context 'when user is admin' do
      before do
        create(:groupable_member, :admin, user: user, group: group)
      end

      it 'updates the group' do
        put :update, params: { id: group.id }.merge(update_params)

        expect(response).to have_http_status(:ok)
        expect(group.reload.name).to eq('New Name')
      end
    end

    context 'when user is editor' do
      before do
        create(:groupable_member, :editor, user: user, group: group)
      end

      it 'updates the group' do
        put :update, params: { id: group.id }.merge(update_params)

        expect(response).to have_http_status(:ok)
        expect(group.reload.name).to eq('New Name')
      end
    end

    context 'when user is member' do
      before do
        create(:groupable_member, user: user, group: group)
      end

      it 'returns forbidden' do
        put :update, params: { id: group.id }.merge(update_params)

        expect(response).to have_http_status(:forbidden)
        expect(group.reload.name).to eq('Old Name')
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:group) { create(:groupable_group) }

    context 'when user is admin' do
      before do
        create(:groupable_member, :admin, user: user, group: group)
      end

      it 'soft deletes the group' do
        delete :destroy, params: { id: group.id }

        expect(response).to have_http_status(:no_content)
        expect(group.reload.active).to be false
        expect(Groupable::Group.unscoped.find(group.id)).to be_present
      end
    end

    context 'when user is editor' do
      before do
        create(:groupable_member, :editor, user: user, group: group)
      end

      it 'returns forbidden' do
        delete :destroy, params: { id: group.id }

        expect(response).to have_http_status(:forbidden)
        expect(group.reload.active).to be true
      end
    end

    context 'when user is member' do
      before do
        create(:groupable_member, user: user, group: group)
      end

      it 'returns forbidden' do
        delete :destroy, params: { id: group.id }

        expect(response).to have_http_status(:forbidden)
        expect(group.reload.active).to be true
      end
    end
  end
end
