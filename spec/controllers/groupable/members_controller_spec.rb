require 'rails_helper'

RSpec.describe Groupable::MembersController, type: :controller do
  routes { Groupable::Engine.routes }

  let(:user) { create(:user) }
  let(:group) { create(:groupable_group) }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:member1) { create(:groupable_member, group: group) }
    let!(:member2) { create(:groupable_member, group: group) }

    before do
      create(:groupable_member, user: user, group: group)
    end

    it 'returns all members of the group' do
      get :index, params: { group_id: group.id }

      expect(response).to have_http_status(:ok)
      members = json
      expect(members.count).to eq(3) # user + member1 + member2
    end
  end

  describe 'GET #show' do
    let(:member) { create(:groupable_member, group: group) }

    before do
      create(:groupable_member, user: user, group: group)
    end

    it 'returns the specific member' do
      get :show, params: { group_id: group.id, id: member.user.id }

      expect(response).to have_http_status(:ok)
      expect(json['id']).to eq(member.id)
      expect(json['user_id']).to eq(member.user_id)
    end

    it 'returns not found for non-existent member' do
      get :show, params: { group_id: group.id, id: 99999 }
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'PUT #update' do
    let(:target_member) { create(:groupable_member, group: group, role: :member) }
    let(:update_params) { { item: { role: 'editor' } } }

    context 'when current user is admin' do
      before do
        create(:groupable_member, :admin, user: user, group: group)
      end

      it 'updates member role' do
        put :update, params: { group_id: group.id, id: target_member.user.id }.merge(update_params)

        expect(response).to have_http_status(:ok)
        expect(target_member.reload.role).to eq('editor')
      end

      it 'can promote member to admin' do
        params = { item: { role: 'admin' } }
        put :update, params: { group_id: group.id, id: target_member.user.id }.merge(params)

        expect(response).to have_http_status(:ok)
        expect(target_member.reload.role).to eq('admin')
      end

      it 'downgrades current admin to editor when promoting another to admin' do
        current_member = group.members.find_by(user: user)
        params = { item: { role: 'admin' } }

        put :update, params: { group_id: group.id, id: target_member.user.id }.merge(params)

        expect(current_member.reload.role).to eq('editor')
        expect(target_member.reload.role).to eq('admin')
      end

      it 'cannot change admin role' do
        admin_member = create(:groupable_member, :admin, group: group)
        params = { item: { role: 'member' } }

        expect {
          put :update, params: { group_id: group.id, id: admin_member.user.id }.merge(params)
        }.to raise_error(StandardError, 'Cannot change admin role')
      end
    end

    context 'when current user is editor' do
      before do
        create(:groupable_member, :editor, user: user, group: group)
      end

      it 'can update member to editor' do
        put :update, params: { group_id: group.id, id: target_member.user.id }.merge(update_params)

        expect(response).to have_http_status(:ok)
        expect(target_member.reload.role).to eq('editor')
      end

      it 'cannot promote to admin' do
        params = { item: { role: 'admin' } }

        expect {
          put :update, params: { group_id: group.id, id: target_member.user.id }.merge(params)
        }.to raise_error(StandardError, 'Only admin can promote to admin')
      end
    end

    context 'when current user is member' do
      before do
        create(:groupable_member, user: user, group: group)
      end

      it 'returns forbidden' do
        put :update, params: { group_id: group.id, id: target_member.user.id }.merge(update_params)

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:target_member) { create(:groupable_member, group: group, role: :member) }

    context 'when current user is admin' do
      before do
        create(:groupable_member, :admin, user: user, group: group)
      end

      it 'deletes the member' do
        target_member # ensure it exists
        expect {
          delete :destroy, params: { group_id: group.id, id: target_member.user.id }
        }.to change { Groupable::Member.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'cannot delete admin member' do
        admin_member = create(:groupable_member, :admin, group: group)

        expect {
          delete :destroy, params: { group_id: group.id, id: admin_member.user.id }
        }.to raise_error(StandardError, 'Admin member cannot be deleted')
      end
    end

    context 'when current user is editor' do
      before do
        create(:groupable_member, :editor, user: user, group: group)
      end

      it 'can delete member' do
        target_member # ensure it exists
        expect {
          delete :destroy, params: { group_id: group.id, id: target_member.user.id }
        }.to change { Groupable::Member.count }.by(-1)

        expect(response).to have_http_status(:ok)
      end

      it 'cannot delete admin' do
        admin_member = create(:groupable_member, :admin, group: group)

        expect {
          delete :destroy, params: { group_id: group.id, id: admin_member.user.id }
        }.to raise_error(StandardError, 'Admin member cannot be deleted')
      end
    end

    context 'when current user is member' do
      before do
        create(:groupable_member, user: user, group: group)
      end

      it 'returns forbidden' do
        delete :destroy, params: { group_id: group.id, id: target_member.user.id }

        expect(response).to have_http_status(:forbidden)
      end
    end
  end
end
